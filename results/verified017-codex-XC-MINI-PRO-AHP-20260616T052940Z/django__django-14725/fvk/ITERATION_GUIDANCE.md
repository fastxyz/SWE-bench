# FVK Iteration Guidance

Status: V2 source edit applied; proof constructed, not machine-checked.

## Applied V2 Change

Apply Finding F-2 and proof obligation PO-7 by enforcing edit-only mode in
`BaseModelFormSet.save()` before virtual dispatch to `save_new_objects()`.

Resulting source behavior:

- `edit_only=True`: `save()` initializes `new_objects` to `[]` and returns only
  `save_existing_objects(commit)`.
- `edit_only=False`: `save()` keeps the previous existing-plus-new behavior.
- Direct calls to the base `save_new_objects()` remain guarded by the V1 check.

## Decisions to Keep V1 Pieces

Keep the V1 `edit_only` class flag and factory keyword propagation. Finding F-3
and PO-6 confirm they are required and satisfied.

Keep the V1 base `save_new_objects()` guard. PO-4 covers direct base-helper
calls and `new_objects` initialization.

Keep validation and management-form counting behavior unchanged. Finding F-4
records that the issue requires preventing creation, not changing validation
semantics for malicious or invalid extra form data.

## Suggested Follow-up Tests

Do not modify tests in this benchmark. In a normal development pass, add tests
for:

- tampered `INITIAL_FORMS`/extra POST data with `edit_only=True`;
- a custom `save_new_objects()` override with `edit_only=True`;
- `new_objects == []` after edit-only save;
- default `edit_only=False` creation behavior;
- inline and generic inline factory propagation.

## Machine-check Follow-up

The proof commands in `PROOF.md` should be run in an environment with K
available. Until `kprove` returns `#Top`, keep all tests and treat the proof as
constructed evidence rather than machine verification.
