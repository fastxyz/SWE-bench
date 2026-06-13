# Code review — V1 fix for django__django-12325

## What V1 changed

In `django/db/models/base.py`, inside `ModelBase.__new__`, the `parent_links`
collection loop was changed from an unconditional dict overwrite:

```python
for field in base._meta.local_fields:
    if isinstance(field, OneToOneField):
        related = resolve_relation(new_class, field.remote_field.model)
        parent_links[make_model_tuple(related)] = field
```

to a guarded assignment that never lets a plain `OneToOneField` overwrite an
already-recorded explicit parent link:

```python
for field in base._meta.local_fields:
    if isinstance(field, OneToOneField):
        related = resolve_relation(new_class, field.remote_field.model)
        related_key = make_model_tuple(related)
        existing = parent_links.get(related_key)
        if (existing is not None and
                existing.remote_field.parent_link and
                not field.remote_field.parent_link):
            continue
        parent_links[related_key] = field
```

The findings below are numbered; `reports/control_notes.md` references them.

---

## F1 — Core correctness: the reported ordering bug is fixed. (PASS)

`parent_links` is consumed only by the **concrete** branch of the later mro loop
(`base.py:251`, `if base_key in parent_links: field = parent_links[base_key]`),
which produces `new_class._meta.parents[base]`. `Options._prepare()`
(`options.py:241-257`) then promotes that field to the pk and raises
`ImproperlyConfigured('Add parent_link=True to …')` if it is not a parent link.

Tracing the issue's two snippets (`Picking(Document)`, `Document` concrete, no
abstract bases — so only the concrete branch runs):

- `document_ptr(parent_link=True)` then `origin(plain)`: `document_ptr` is
  recorded first; when `origin` is seen, `existing` is the parent link and the
  new field is not → `continue`, keeping `document_ptr`. ✔
- `origin(plain)` then `document_ptr(parent_link=True)`: `origin` recorded
  first; `document_ptr` is a parent link → guard is False → overwrite, giving
  `document_ptr`. ✔

Both declaration orders now select `document_ptr`, so the error no longer
depends on field order. Matches the issue's expectation that the explicit
`parent_link=True` marker should make order irrelevant.

## F2 — Secondary symptom (runtime "`document_ptr_id` not populated") is fixed. (PASS)

The ticket reports that even with the `primary_key=True` work-around the model
is broken unless field order is correct. That symptom is downstream of the same
root cause: `_meta.parents[Document]` held the wrong field. With V1,
`_meta.parents[Document] == document_ptr` regardless of order, so the parent
link is wired up correctly and the work-around is no longer needed. No separate,
order-dependent code path produces this symptom independently of `_meta.parents`
(verified: `get_ancestor_link` and the SQL compiler read from `_meta.parents`).

## F3 — Regression guard: `test_missing_parent_link` still raises. (PASS — and dictates the design)

`invalid_models_tests` (and `model_inheritance`) require that a lone
`OneToOneField` to the parent **without** `parent_link=True` is still treated as
the (invalid) parent link so the helpful `Add parent_link=True to …` error is
raised. V1 still records non-parent-link fields in `parent_links` (it only
changes *which* field wins per key), so the single-field case is unchanged and
the error is preserved. This is the explicit reason the fix must **not** be the
tempting one-liner `if isinstance(field, OneToOneField) and
field.remote_field.parent_link:` — filtering to parent links only would make
Django silently auto-create a `*_ptr` field and break this contract.

## F4 — Regression guard: `test_abstract_parent_link` unaffected. (PASS)

For `class C(B)` with abstract `B(A)` declaring `a = OneToOneField(A,
parent_link=True)`, `A` is not a *direct* base of `C`, so the concrete branch
for `A` never runs; the parent link is established through the **abstract**
branch (`base.py:281-299`) via `base_parents` copying, which does not consult
`parent_links`. V1's change to `parent_links` is therefore moot here, and
`C._meta.parents[A] is C._meta.get_field('a')` still holds.

## F5 — Regression guard: explicit parent link beside an unrelated `ForeignKey`. (PASS)

`model_inheritance.ParkingLot(Place)` declares `parent =
OneToOneField(Place, parent_link=True, primary_key=True)` plus `main_site =
ForeignKey(Place)`. The `ForeignKey` is not a `OneToOneField`, so the
`isinstance` guard skips it; `parent_links[Place] == parent`. Unchanged.

## F6 — Multiple-parent MTI is handled and order-independent. (PASS)

For `class C(A, B)` declaring `a_ptr`/`a_extra` to `A` and `b_ptr`/`b_extra` to
`B`, the guard is applied per `related_key`, so `parent_links[A] == a_ptr` and
`parent_links[B] == b_ptr` regardless of the interleaved declaration order. The
key order of `_meta.parents` is set by the mro loop, not by `parent_links`, so
multi-parent pk selection (`options.py:245 next(iter(self.parents.values()))`)
is unchanged.

## F7 — Edge case: two `parent_link=True` fields to the same parent. (NOTE — no regression)

This is an invalid configuration and there is no system check for it (confirmed:
no such check in `django/core/checks`). V1 keeps the last one (the second
parent-link field has `field.remote_field.parent_link` True, so the guard is
False and it overwrites). The original code also kept the last field, so V1
introduces no behavior change for this invalid case.

## F8 — Edge case: cross-base interaction with abstract field copying. (NOTE — washes out, no regression)

V1 differs from the original `parent_links` value only when a `parent_link=True`
field is encountered *before* a plain field to the same parent. Across bases
this requires the parent link to live on an **abstract** base. But whenever an
abstract base contributes a parent link, the abstract branch
(`base.py:299 new_class._meta.parents.update(base_parents)`) re-assigns
`_meta.parents[parent]` to the **deep-copied** field independently of
`parent_links`. So the differing intermediate `parent_links` value is
overwritten and the final `_meta.parents` is identical to the original in
realistic (single-concrete-parent) cases. In a contrived
`class C(AbstractMixinWithParentLinkToP, P)` ordering where the concrete branch
runs after the abstract branch, V1 yields a *working* model (because
`options.py:249-251` re-resolves the parent link to the child's local field by
name) where the original would have raised — i.e. V1 is no worse, and arguably
better, even there.

## F9 — Error handling / null-safety. (PASS)

`field.remote_field` is always present for a `OneToOneField` (it is a relation
field), and `parent_link` is always set on the relation (defaults to `False`
via `ForeignKey.__init__`/`ForeignObjectRel`). Both `field.remote_field.parent_link`
and `existing.remote_field.parent_link` are therefore safe; the change adds no
new exception paths.

## F10 — No parallel parent-link-selection path is left unfixed. (PASS)

`Options.get_ancestor_link` (`options.py:613-631`) and the SQL compiler/query
layer read the resolved field out of `_meta.parents`; migrations reconstruct
models through this same metaclass. There is no second place that re-derives the
parent link from raw `OneToOneField`s, so fixing the `parent_links` collection
is sufficient. Bonus: migration-rendered models (whose field order may differ
from the source definition) become robust because V1 is order-independent.

## F11 — Style / conventions. (PASS)

The parenthesized multi-line `if` matches Django's style; the explanatory
comment states intent; computing `related_key` once is a minor readability gain
over the original inline `make_model_tuple(...)`. No new imports are required
(`OneToOneField`, `resolve_relation`, `make_model_tuple` already imported).

## F12 — Scope: speculative enhancements intentionally omitted. (JUSTIFIED)

The ticket discussion floats two larger ideas: (a) "a pk OneToOne to the MTI
child should imply parent link" (so `parent_link=True` would be unnecessary),
and (b) keying `parent_links` by `related_name`. Both are out of scope for this
bug: (a) is a debated behavior change that would muddy the documented
requirement enforced by F3; (b) is unnecessary because MTI has exactly one
parent link per parent — the fix is to pick the *right* field for the existing
key, not to allow several. Neither is implemented.

## F13 — Comparison with the ticket's suggested PR. (NOTE — V1 retained)

The community PR uses `sorted(fields, key=lambda x: x.remote_field.parent_link,
reverse=True)` with `if related_key not in parent_links`. For the reported bug
and all realistic cases it is behaviorally equivalent to V1 (within a single
base the sort puts the parent link first and `not in` selects it). Combined with
the outer `reversed([...])` loop it flips cross-base precedence to "first base
wins," which is only observable in the same contrived multi-base cases discussed
in F8 (and there those parent links are handled by the abstract branch anyway).
V1's explicit guard expresses the intent ("don't shadow a parent link") more
directly and is at least as correct, so no reason to switch.

---

## Verdict

V1 is correct, minimal, regression-safe, and complete for the issue as
described. **Confirm V1 unchanged** (see `reports/control_notes.md`). No code
edits are warranted; making any would add churn without changing behavior.
