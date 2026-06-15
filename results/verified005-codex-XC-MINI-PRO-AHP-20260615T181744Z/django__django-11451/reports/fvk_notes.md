# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no production-code problem requiring a
V2 edit.

## Trace to Findings and Proof Obligations

- `F-001` is the reported null-username lookup bug. It is discharged by
  `PO-001` and `PO-002`: V1 normalizes the username from `kwargs` first, then
  returns before `get_by_natural_key()` when the normalized username is `None`.
- `F-002` covers the prompt's second incomplete-credential case,
  `password is None`. It is also discharged by `PO-002`: the same guard returns
  before lookup, dummy hashing, password checking, or `user_can_authenticate()`.
- `F-003` confirms that the nonexistent-user timing mitigation remains intact.
  `PO-003` traces this to the complete-credential path, where the new guard does
  not fire and the original `UserModel().set_password(password)` call remains.
- `F-004` confirms complete-credential success and failure behavior remains
  intact. `PO-004`, `PO-005`, and `PO-006` trace the unchanged found-user
  branches.
- `F-005` is a proof boundary, not a source defect. `PO-008` records that the
  FVK model is event-based and partial-correctness only, so it justifies the
  no-query/no-hash property but not full Django ORM or password-hasher
  semantics.
- `F-006` is a test recommendation. It did not justify editing tests because the
  task forbids modifying test files.

## Source Changes

No source files were changed during the FVK phase. The existing V1 change in
`repo/django/contrib/auth/backends.py` remains the minimal fix justified by the
audit.

## Commands Not Run

The FVK artifacts include K commands in `fvk/PROOF.md`, but they were not
executed because this task forbids K tooling, Python, and tests.

