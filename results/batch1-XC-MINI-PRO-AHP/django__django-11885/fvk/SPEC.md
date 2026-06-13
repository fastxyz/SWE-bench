# SPEC.md — formal specification of the V1 fast-delete-combination fix

**Status: constructed, not machine-checked** (the MVP builds the specs/proofs and
emits the `kompile`/`kprove` commands but does not run the K toolchain; no
execution environment is available here).

Target: `django__django-11885` — *Combine fast delete queries*. The V1 fix lives
in `repo/django/db/models/deletion.py` (`Collector.collect`, `related_objects`,
`get_del_batches`, `can_fast_delete`) and `repo/django/contrib/admin/utils.py`
(`NestedObjects.related_objects`).

This document states, for each changed function, the **intended** behavior
(inferred from `benchmark/PROBLEM.md` + the surrounding code), the
precondition/postcondition contract, and the side conditions. The K artifacts
(`fvk/mini-deletion.k`, `fvk/mini-deletion-spec.k`) formalize the algebraic core;
this note is the developer-readable companion (formalize.md step 6).

---

## 0. Intent (from `benchmark/PROBLEM.md`)

When `deletion.Collector` emulates `ON DELETE CASCADE`, a related object that
qualifies for the *fast-delete* path is removed by a bare
`DELETE FROM t WHERE fk IN (…)`. When **several FKs on the same table `t`** point
at the object being deleted, V0 issued one `DELETE` per FK. Intended behavior:
issue **one** `DELETE FROM t WHERE fk1 IN (…) OR fk2 IN (…) …` per table,
reducing round-trips, **without changing which rows get deleted or the reported
counts**.

Notation used below: for a fast-deletable related model `t` with FK fields
`f_0..f_{m-1}` (all CASCADE) pointing at the deleted objects `O`, let
`S_k = { rows of t : t.f_k ∈ O }` (the rows the k-th FK selects). The deletion
target for table `t` is the **union** `S_0 ∪ … ∪ S_{m-1}`.

---

## 1. `related_objects(self, related_model, related_fields, objs)`

**Intent.** Build the queryset of `related_model` rows referencing `objs` through
**any** field in `related_fields`, combined with OR.

**Contract.**
- **Pre:** `related_fields` is a non-empty iterable of FK fields of
  `related_model`; `objs` is a collection of model instances (or a batch thereof).
- **Post:** returns `related_model._base_manager.using(self.using).filter(P)`
  where `P = Q(f_0__in=objs) ∨ … ∨ Q(f_{m-1}__in=objs)`, i.e. a **lazy** queryset
  whose selected row set is `rows(P) = S_0 ∪ … ∪ S_{m-1}`.
- **Side condition (non-empty):** `m = len(related_fields) ≥ 1`. `reduce(or_, …)`
  with an empty iterable and no initial value raises `TypeError`. (Finding F4.)

**Formalized as.** The `rows()` homomorphism `rows(p or q) = rows(p) ∪ rows(q)`
and the `(COMBINE)` claim in `mini-deletion-spec.k`: `rows(result) = bigU(0, m)`.

**Equivalence to V0.** V0's `related_objects(related, objs)` returned the
single-field queryset for `S_k`; V1 returns one queryset for the union. With
`m = 1`, `rows(P) = S_0` — identical to V0.

---

## 2. `get_del_batches(self, objs, fields)`

**Intent.** Partition `objs` into batches small enough that a query whose WHERE
clause contains **one IN-list per field in `fields`** stays within the backend's
parameter budget.

**Contract.**
- **Pre:** `fields` is a non-empty list of fields; `objs` a list.
- **Post:** returns a list of slices `B_0, …, B_{r-1}` of `objs` such that
  (a) they **partition** `objs` in order (`concat = objs`, disjoint, order
  preserved), and (b) each `|B_j| ≤ conn_batch_size` where
  `conn_batch_size = max(bulk_batch_size([f.name for f in fields], objs), 1)`.
- **Parameter-budget side condition (Finding F3).** A combined query over a batch
  `B_j` uses `m · |B_j|` bind parameters. With the backends that cap parameters
  (`max_query_params` finite) `bulk_batch_size` returns `max_query_params // m`,
  so `m · |B_j| ≤ max_query_params` **provided `m ≤ max_query_params`**. Backends
  with `max_query_params = None` (PostgreSQL, MySQL) return `len(objs)` and do
  **not** divide by `m`: there the budget is the backend's declared "send
  everything," and a combined query carries `m ×` the parameters of a V0
  single-field query (see Findings/PROOF_OBLIGATIONS, PO-BATCH).

**Equivalence to V0.** V0 took a single `field`; it called
`bulk_batch_size([field.name], objs)`. V1 with `fields == [field]` computes the
identical `field_names == [field.name]` and the identical batches — byte-for-byte
backward compatible on the single-field path.

---

## 3. `can_fast_delete(self, objs, from_field=None)` — the `objs._meta.model` change

**Intent (unchanged).** Decide, **purely from the model and `from_field`**,
whether a model's rows can be fast-deleted (no cascades into it, no signals, no
GFK, parents only via `from_field`). The decision never inspects actual rows.

**Contract.** `can_fast_delete(x, from_field=f)` depends only on `model(x)` and
`f`, where
```
model(x) = x._meta.model      if x has _meta   (an instance OR a model class)
         = x.model            if x is a queryset-like
```
**Post / equivalence:** for every input V0 ever passed (a model **instance** or a
**queryset**), `x._meta.model == type(x)` for an instance and the queryset branch
is untouched, so the boolean result is identical to V0. **Additionally**, a model
**class** `C` is now accepted with `model(C) = C._meta.model = C`, which V0's
`type(C)` (= the metaclass) would have mishandled. This is the enabling change
that lets `collect` decide fast-deletability **once per relation** before any
queryset is built.

**Why `x._meta.model == type(x)` for instances.** `Options.model` is bound to the
class that owns the `Options`; for any instance `obj`, `obj._meta` is that class's
`Options`, so `obj._meta.model is type(obj)` (true for concrete, proxy, and MTI
child instances — each owns its `_meta`). See Finding F1.

---

## 4. `Collector.collect(...)` — the grouping (the behavioral spec)

**Intent.** Produce a set of fast-delete querysets that, when each is
`_raw_delete()`-d, deletes **exactly the same table rows** as V0 — but with the
queries for the same table **merged**.

**Contract (the central one).** Let `R` be the fast-deletable reverse relations of
the model being collected, grouped by target table:
`group(t) = [ related.field for related in R if related.related_model is t ]`
(only fields that individually pass `can_fast_delete(t, from_field=field)`).

- **V0 fast-delete set for `t`:** `⋃_{f ∈ group(t)} ⋃_{batch} { rows of t : t.f ∈ batch }`
  issued as `|group(t)| · (#batches per field)` separate `DELETE`s.
- **V1 fast-delete set for `t`:**
  `⋃_{batch} rows( ⋁_{f ∈ group(t)} Q(f__in=batch) )`
  issued as `(#batches over all fields)` combined `DELETE`s.

- **Post (row-set invariance):** the two sets are **equal** for every `t`
  (`PO-ROWSET`). Hence the deleted-row multiset and the per-table reported counts
  are identical (`PO-COUNT`), and the number of fast-delete statements is **≤**
  V0's (`PO-FEWER`).
- **Pre / side conditions:** fast-deletable models have no inbound cascades or
  signals, so they have **no inter-dependencies** — combining and reordering them
  is sound (`PO-ORDER`). Querysets stay **lazy** (no `if sub_objs:` evaluation on
  the fast path), as in V0 (`PO-LAZY`).

**Non-fast path unchanged.** Relations that are *not* fast-deletable still run the
per-`[field]` batch loop, the `.only(...)` deferral, the `if sub_objs:` guard, and
`field.remote_field.on_delete(...)` exactly as V0 — now via the new
`related_objects(t, [field], batch)` / `get_del_batches(new_objs, [field])`
signatures that are byte-compatible for a single field (§1–2).

---

## 5. `NestedObjects.related_objects` (admin) and `NoFastDeleteCollector`

Both admin/contenttypes `Collector` subclasses override `can_fast_delete` to
return **`False`**. Therefore `model_fast_deletes` is always empty for them, the
combine loop never runs, and `related_objects` is only ever called from the
non-fast path with a **single** field. The `NestedObjects` override is updated to
the new signature and applies `select_related(*[f.name for f in related_fields])`,
which for the single-field input is identical to V0's
`select_related(related.field.name)`. `NoFastDeleteCollector` overrides neither
changed-signature method, so it needs no edit. (Findings F6.)

---

## 6. What is proved vs assumed

- **Proved (constructed):** the OR-fold computes the union of field row sets
  (`(COMBINE)`/`(FOLD)` claims); row-set and count invariance vs V0; batch
  partitioning; the single-field backward-compat equalities.
- **Trusted base:** the `rows()` homomorphism `rows(p or q) = rows(p) ∪ rows(q)`
  (faithful to SQL `OR` semantics on a single table with no joins — justified in
  PROOF.md §A), the mini-X fragment's adequacy, and the reachability metatheory.
- **Out of fragment / escalated:** the live ORM lookup compilation (that
  `Q(fk__in=objs)` compiles to a join-free `fk_id IN (…)`), and the backend
  `bulk_batch_size` contracts — handled as PROOF.md side notes, not re-derived in
  K.
