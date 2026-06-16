# ITERATION GUIDANCE

## Decision

V1 stands unchanged. The FVK audit did not surface a source-code problem requiring a V2 edit.

## Why no further source edit is needed

- F-001 and PO-001 identify the original defect: committed `UserCreationForm.save()` did not persist m2m form data. V1 adds the missing `self.save_m2m()` call.
- F-002 and PO-002 require `user.save()` before m2m persistence. V1 places `self.save_m2m()` immediately after `user.save()`.
- F-003 and PO-004 require `commit=False` to remain deferred. V1 guards the new call with `if commit:`.
- F-004 and PO-007 require compatibility. V1 does not change the public method signature, returned object, or admin deferred-save flow.

## Recommended next checks in an execution-capable environment

1. Run the K commands in `PROOF.md`.
2. Run Django's relevant auth/model-form tests.
3. Add or keep a regression test for a custom user creation form with a many-to-many field saved through `form.save()` / `commit=True`.
4. Keep `commit=False`, admin integration, invalid-form, and password validation tests; the constructed proof does not replace those without machine-checking and broader modeling.

## Open items

No open source-code finding remains for the reported issue. The only unresolved item is proof execution: this workspace forbids running K tooling, tests, or Python, so the proof remains constructed rather than machine-checked.
