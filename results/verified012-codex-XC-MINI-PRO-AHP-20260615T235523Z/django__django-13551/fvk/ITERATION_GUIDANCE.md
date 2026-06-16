# Iteration Guidance

Status: V1 stands unchanged.

## Decision

No source changes are required after the FVK audit. V1 discharges the
intent-derived obligations in `fvk/PROOF_OBLIGATIONS.md`:

- PO1/PO3: email is now part of the token hash state, so concrete email changes
  invalidate old reset tokens.
- PO4: custom users without a concrete email attribute remain supported.
- PO5: custom email field names are honored via `get_email_field_name()`.
- PO6/PO7: existing token behavior and public call shapes are preserved.

## Future test recommendations

Do not delete existing tests based on this constructed proof. If this were a
normal Django development branch, add tests for:

- generated token fails after `user.email` changes;
- generated token fails after a custom `EMAIL_FIELD` value changes;
- generated token remains constructible for an `AbstractBaseUser` subclass with
  no concrete email attribute.

## Future proof recommendations

Run the recorded K commands in `fvk/PROOF.md` in an environment with K installed.
If `kprove` does not return `#Top`, update `fvk/FINDINGS.md` with the residual
obligation before changing code.

For stronger assurance beyond the FVK MVP, replace the abstract digest
constructor with a richer cryptographic model or explicitly document the HMAC
collision-resistance assumption as part of Django's token security contract.
