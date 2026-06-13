# Control notes — django__django-11400 (V2 decisions)

## Summary of decision
After a systematic, skeptical re-review of the V1 fix (recorded in
`review/FINDINGS.md`), **V1 stands unchanged**. The review verified the fix end-to-end
against the Django ORM internals and found it correct, complete, minimal, and free of
regressions. No source edits were made in this pass. Every decision below traces to
numbered findings in `review/FINDINGS.md`.

## What V1 did (recap)
1. `django/db/models/fields/__init__.py` `Field.get_choices()` — apply `.order_by(*ordering)`
   only when `ordering` is non-empty.
2. `django/db/models/fields/reverse_related.py` `ForeignObjectRel.get_choices()` — same.
3. `django/contrib/admin/filters.py` — extracted `field_admin_ordering()` helper on
   `RelatedFieldListFilter`; `RelatedOnlyFieldListFilter.field_choices()` now forwards
   `ordering=`.

## Decision 1 — Keep the `if ordering:` guard in both `get_choices()` methods
Kept as-is. **Justification: F1, F2, F3, F4, F10.**
- F1 verifies the mechanism: not calling `.order_by()` leaves `default_ordering=True`
  (`sql/query.py:168`), `complex_filter()` preserves it (`query.py:916`), and the compiler
  then uses `Meta.ordering` (`sql/compiler.py:263-273`). This is precisely the requested
  fallback and is the single most important correctness check; it passed.
- F2 / F3 confirm both halves of the reported issue are fixed.
- F4 confirms the precedence (admin ordering overrides `Meta.ordering`) is right.
- F10 confirms models with no ordering at all are not regressed.
An alternative formulation considered and rejected: have `filters.py` pass
`field.remote_field.model._meta.ordering` explicitly as the fallback. Rejected because it
would duplicate logic, diverge between forward vs. reverse relations, and bypass the
canonical default-ordering path; fixing it inside `get_choices` makes `ordering=()` mean the
natural "no explicit ordering, use the model default," which is the more correct API
contract (same reasoning as recorded in V1's baseline notes).

## Decision 2 — Keep `field_admin_ordering()` helper + `field_choices()` delegation
Kept as-is. **Justification: F8, F9.**
- F8 confirms the helper reuses the original `field.remote_field.model` registry lookup
  verbatim (valid for forward and reverse relations via `reverse_related.py:62-64`), so the
  refactor is behavior-preserving for the ordering source.
- F9 confirms it is backward compatible: additive method, unchanged `field_choices`
  signature, no break for third-party subclasses.

## Decision 3 — Keep `RelatedOnlyFieldListFilter` forwarding `ordering=`
Kept as-is. **Justification: F3, F4, F12.**
- F3 / F4: this is the actual fix for the second reported defect and yields the correct
  precedence.
- F12 notes that `RelatedOnly` on a *reverse* relation has a pre-existing `limit_choices_to`
  incompatibility with `ForeignObjectRel.get_choices()`. This is NOT introduced by V1 (the
  `limit_choices_to` kwarg predates it; V1 only added `ordering=`, which the reverse
  signature accepts). Fixing it is out of scope for this issue, so it was deliberately left
  alone to keep the change minimal and targeted.

## Decision 4 — Keep `.all()` in the reverse `get_choices()`
Kept as-is. **Justification: F7.** A Manager is not directly iterable, so `.all()` is
required to obtain the QuerySet when the `order_by` call is skipped; it also yields the
`default_ordering=True` queryset needed for the `Meta.ordering` fallback. Mirrors the forward
implementation's shape.

## Decision 5 — No change to the form/choice-field path
No edit needed. **Justification: F5, F14.** The modified block runs only when
`self.choices is None`; `formfield()` and `formfield_for_choice_field()` reach
`get_choices()` only for fields that declare `choices`, returning early before the ordering
code. Blank-choice handling is independent of ordering. Nothing to change.

## Decision 6 — Do not modify tests or test fixtures
No edit. **Justification: F6 + task constraints.** Existing `GetChoicesOrderingTests` all use
non-empty `ordering`, so they pass unchanged. Test files are out of bounds per the task, and
the fixture models (`Foo`/`Bar`) are left untouched.

## Decision 7 — Do not edit docs / release notes
No edit. **Justification: F15.** `get_choices()` is undocumented (semi-internal) and release
notes are not part of testable behavior; the task requires a minimal, targeted code change.

## Decision 8 — Accept noted pre-existing limitations without action
**Justification: F12, F13.** The reverse-relation `limit_choices_to` issue (F12) and the
theoretical cross-relation `Meta.ordering` duplication (F13) both predate this fix, are
extreme/rare, and are orthogonal to the reported bug. Addressing them would expand scope and
risk unrelated regressions, so they are documented and left as-is.

## Residual risk assessment
Low. The only behavioral change is that relational `get_choices()` calls with an empty
`ordering` now honor the related model's `Meta.ordering` (and any custom-manager ordering —
F11) instead of force-clearing it. This is the intended fix, is confined to the admin related
list filters in practice (F5), and is consistent with the ORM's documented default-ordering
semantics (F1).
