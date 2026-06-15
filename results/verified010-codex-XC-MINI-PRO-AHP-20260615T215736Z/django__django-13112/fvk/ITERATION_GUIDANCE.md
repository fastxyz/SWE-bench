# Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Decision

V1 stands unchanged. The formal obligations in `fvk/PROOF_OBLIGATIONS.md` are satisfied by the existing V1 edit in `repo/django/db/models/fields/related.py`.

## Why no source edit was added in the FVK pass

- F1 is resolved by PO1 and PO2: the app label is preserved and only the model component is lowercased.
- F2 and F3 confirm frame conditions in PO3 and PO5: the concrete-model and swappable branches do not reintroduce whole-reference lowercasing.
- F4 is a non-blocking audit note under PO4 and PO6: the adjacent migration operation utility is not on the `Field.clone()` -> `StateApps` lazy-reference failure path.

## Recommended future tests

The benchmark forbids modifying tests in this pass. For a normal Django contribution, add or keep tests that cover:

- A mixed-case app label model state with `ForeignKey(Category)` surviving repeated `field.clone()` or migration state rendering as `DJ_RegLogin.category`.
- The reported failure path through `StateApps` not producing a pending lazy operation for `dj_reglogin.category`.
- Existing lowercase app-label projects still serializing unchanged.

## Separate follow-up candidate

A broader migration audit could examine whether `django/db/migrations/operations/utils.resolve_relation()` should preserve app label case for dotted strings. That is not required for this issue because it is not the source of the reported lazy-reference key.

