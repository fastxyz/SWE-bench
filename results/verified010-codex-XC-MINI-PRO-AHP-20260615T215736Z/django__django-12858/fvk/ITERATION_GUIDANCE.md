# ITERATION_GUIDANCE.md

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

## Rationale

- F-001 and PO-1 confirm that V1 fixes the reported false positive by accepting a final registered lookup.
- F-002 and PO-3 confirm that V1 does not broadly accept lookup names in the middle of a path.
- F-003 and PO-2 confirm that V1 preserves registered transform handling.
- F-004 and PO-5 confirm that V1 does not change public/check-framework API shape.

## Next Code Iteration

No source edit is justified by the FVK findings. A later code iteration should only revisit `Model._check_ordering()` if one of these occurs:

- A machine check of `ordering-check-spec.k` does not return `#Top`.
- Django's executable test suite exposes a case outside the current proof obligations.
- Public intent is clarified to require a stricter subset of registered final lookups than "registered lookup on the previously resolved field."

## Suggested Tests for an Execution-Capable Environment

Do not modify tests in this task. In a normal development environment, add or keep coverage for:

- `Meta.ordering = ('supply__product__parent__isnull',)` produces no `models.E015`.
- `Meta.ordering = ('-supply__product__parent__isnull',)` produces no `models.E015`.
- `Meta.ordering = ('parent__isnull__bogus',)` still produces `models.E015` unless `isnull` is also a registered transform that can validly continue the chain.
- Existing transform ordering, such as `test__lower` with `Lower` registered, still produces no `models.E015`.

## Commands to Run Later

Recorded only; not executed in this workspace:

```sh
cd fvk
kompile mini-django-ordering.k --backend haskell
kast --backend haskell ordering-check-spec.k
kprove ordering-check-spec.k
```
