# Code review — V1 fix for django__django-11885 ("Combine fast delete queries")

Scope reviewed: `django/db/models/deletion.py` (imports, `can_fast_delete`,
`get_del_batches`, `collect`, `related_objects`) and `django/contrib/admin/utils.py`
(`NestedObjects.related_objects`). Reviewed against `benchmark/PROBLEM.md` and the
surrounding code (`sql/subqueries.py`, `sql/query.py`, backend `bulk_batch_size`,
`db/models/query.py`, the other `Collector` subclass `NoFastDeleteCollector`).

Legend: ✅ = confirmed correct / no action; ⚠️ = noted risk that was analyzed and
judged acceptable; ❌ = defect requiring a code change. No ❌ findings were found.

---

## F1 — Correctness against the issue (the actual combination). ✅
The issue asks that fast deletes targeting the same table be merged with `OR`,
e.g. `DELETE FROM entry WHERE created_by_id IN (...) OR updated_by_id IN (...)`.

V1 groups reverse relations by `related_model` into `model_fast_deletes`
(`deletion.py:219,228-229`) and, after the relation loop, builds one combined
queryset per batch (`deletion.py:249-253`) via
`related_objects(related_model, related_fields, batch)`, which produces
`reduce(or_, Q(field__in=objs) for field in related_fields)`
(`deletion.py:264-268`). For the canonical `Entry(created_by, updated_by)` /
`Person.friends` examples this yields exactly the single OR'd `DELETE` the issue
requests. **Confirmed: matches the requested behavior.**

## F2 — Parameter-limit safety across backends (the key edge case). ✅/⚠️
Combining N foreign keys multiplies the bound-parameter count of a batch by N
(`f1 IN (batch) OR f2 IN (batch) OR …`). V1 keeps this safe by combining **before**
batching and passing the *whole field list* to `get_del_batches`, which forwards
`[field.name for field in fields]` to `bulk_batch_size` (`deletion.py:163-169`):

- SQLite (`max_query_params=999`) and Oracle (`max_query_params=65535`) override
  `bulk_batch_size` to return `max_query_params // len(fields)` for >1 field, so a
  combined batch has `batch_size * N ≤ max_query_params`. Safe.
- PostgreSQL/MySQL inherit the base `bulk_batch_size`, which returns `len(objs)`
  and ignores field count (`max_query_params = None`). These backends have no hard
  bound-parameter-count limit that this would violate (psycopg2 binds client-side;
  MySQL is bounded by `max_allowed_packet` size, which comfortably holds realistic
  combined deletes).

This is exactly the contract `bulk_batch_size(fields, objs)` is designed for, so
V1 uses the API correctly. ⚠️ In a pathological case (e.g. a single model with
dozens of FKs to the deleted model on a packet-limited backend) the combined query
could grow large, but this is no worse than the documented batch contract and is
not a realistic regression. **Confirmed: correct and the reason the combination is
done at collection time rather than post-hoc in `delete()`.**

## F3 — Deleted-row count semantics are preserved. ✅
`delete()` still sums `qs._raw_delete()` rowcounts per `qs.model._meta.label`
(`deletion.py:322-325`). With separate per-field queries the second query never
re-counts rows the first already deleted, so the old total equalled the size of the
*union*; the combined `OR` query deletes that same union in one statement and
reports the union's rowcount. The total returned by `delete()` and the per-model
breakdown are unchanged. **Confirmed.**

## F4 — Per-field fast-delete eligibility is still respected (incl. MTI). ✅
`can_fast_delete` depends on `(model, from_field)`, never on row contents. V1 now
calls it once per relation as `can_fast_delete(related_model, from_field=field)`
(`deletion.py:228`) and only groups fields for which it returns `True`; ineligible
relations fall through to the unchanged non-fast path. Because the `from_field`
argument is still the specific relation's field, the parent-link check
(`all(link == from_field for link in parents.values())`) continues to work, so MTI
child fast deletes (`test_fast_delete_inheritance`) and the
"regular-FK-vs-parent-link to the same model" distinction are decided per field
exactly as before — only the eligible ones get combined. **Confirmed.**

## F5 — Nullable / CASCADE-only combination semantics. ✅
Only `CASCADE` fields can be fast-deleted (`can_fast_delete` returns `False` for
`from_field.remote_field.on_delete is not CASCADE`), so every field grouped under a
model is a CASCADE FK whose rows must be removed. `NULL`s never match `IN`, so
`fk1 IN (...) OR fk2 IN (...)` deletes precisely the rows referencing the deleted
objects via any cascading FK — identical union to the old per-field deletes.
**Confirmed.**

## F6 — No subquery / join is introduced; `delete_qs` stays single-table. ✅
Filtering an FK/O2O with `__in` against instances compares the local `*_id`
column (no join); OR-ing two such conditions keeps only the base table in
`alias_map`. In `DeleteQuery.delete_qs` (`sql/subqueries.py:44-76`) this makes
`innerq_used_tables == tuple(self.alias_map)`, so the combined `WHERE` is copied
directly (`DELETE FROM t WHERE a IN (...) OR b IN (...)`) rather than degrading to
the `pk__in=subquery` branch. **Confirmed: efficient direct delete, as intended.**

## F7 — Subclass / API-signature compatibility. ✅ (with ⚠️ for 3rd parties)
`related_objects` and `get_del_batches` changed signatures. In-repo overriders:
- `NestedObjects` (admin) — override updated to the new signature and
  `select_related(*[f.name for f in related_fields])` (`admin/utils.py:185-187`).
  Since `NestedObjects.can_fast_delete` always returns `False`, `related_fields` is
  always a single `[field]`, so behavior is identical to the old
  `select_related(related.field.name)`.
- `NoFastDeleteCollector` (contenttypes) — only overrides `can_fast_delete`
  (`*args, **kwargs` → `False`); it does not override `related_objects`/
  `get_del_batches`, so it transparently uses the new base implementations via the
  non-fast path with single-field lists. No change needed.

⚠️ Third-party `Collector` subclasses overriding `related_objects`/`get_del_batches`
would need updating — this is an intentional, accepted internal-API change (the
methods are undocumented extension points). No in-repo or docs references break
(verified: no `docs/` references to these methods). **Confirmed for this codebase.**

## F8 — Non-fast path is byte-for-byte equivalent. ✅
The non-fast branch always calls `related_objects(related_model, [field], batch)`
(`deletion.py:233`) and `get_del_batches(new_objs, [field])` (`deletion.py:231`).
`reduce(or_, [Q(field__in=objs)])` returns the single `Q` unchanged, so
`filter(Q(field__in=objs))` is the same SQL as the old
`filter(**{field.name+'__in': objs})`, and single-element `[field.name]` yields the
same `bulk_batch_size`. The deferring/`only()` logic and the `on_delete` dispatch
are unchanged. **Confirmed: only the new fast-delete grouping changes behavior.**

## F9 — Error handling / empty inputs. ✅
`reduce(or_, …)` with no initial value would raise on an empty iterable, but
`related_fields` is never empty: the non-fast path passes a literal `[field]`, and
`model_fast_deletes[related_model]` keys are only created by appending a field.
`objs` passed to `related_objects` is always a non-empty list slice (guarded by
`if not new_objs: return` at `deletion.py:200`). **Confirmed: no new failure mode.**

## F10 — Imports / circular-import safety / `_meta.model` equivalence. ✅
New imports: `defaultdict`, `functools.reduce`, `operator.or_`, and
`django.db.models.query_utils` (`deletion.py:1-7`). `query_utils` is the module
explicitly factored out to be importable without circular-import issues; it imports
only `constants` and `utils.tree`, so importing it while `django.db.models.__init__`
is still initializing `deletion` (line 7 of that `__init__`) is safe — consistent
with the pre-existing `from django.db.models import signals, sql`.
`can_fast_delete`'s `type(objs)` → `objs._meta.model` (`deletion.py:141`) is exact:
`Options.model` is the model class for both an instance and a class, so existing
instance/queryset call sites are unaffected while a model class may now be passed.
**Confirmed.**

## F11 — Determinism / ordering of combined fast deletes. ✅
`model_fast_deletes` is a `defaultdict` (insertion-ordered) populated in
`get_candidate_relations_to_delete` order, and within `delete()` all fast deletes
run before any tracked-instance delete inside `transaction.atomic`. Fast-deletable
models have no inbound cascades or signals, so they carry no inter-dependencies and
reordering among them is safe (the original code likewise did not topologically
sort `fast_deletes`). Query order is deterministic, avoiding flaky `assertNumQueries`
ordering issues. **Confirmed: no ordering regression.**

## F12 — Consistency with visible tests (sanity cross-check, not modifiable). ✅
Reasoned through the visible `tests/delete/` query-count assertions:
`test_large_delete`, `test_large_delete_related`, `test_fast_delete_*`,
`test_fast_delete_inheritance`, `test_fast_delete_instance_set_pk_none`. All involve
single-FK relations or the top-level fast path, where V1 preserves the exact query
counts (single-field batching is unchanged). The new multi-FK combination is an
*additional* reduction not contradicted by any visible assertion. **Confirmed.**

## F13 — Documentation / release note. ⚠️ (out of scope)
A real upstream change would add a 3.1 release note; this is irrelevant to the
behavioral fix and the hidden test suite, and the task asks for a minimal,
test-targeted change, so no docs are edited.

---

## Conclusion
No correctness, edge-case, error-handling, or regression defects were found
(no ❌). The two ⚠️ items (F2 pathological packet size, F7 third-party subclass
signature) are inherent to the chosen approach, match Django's existing API
contracts, and are not regressions for this codebase. **V1 stands unchanged.**
