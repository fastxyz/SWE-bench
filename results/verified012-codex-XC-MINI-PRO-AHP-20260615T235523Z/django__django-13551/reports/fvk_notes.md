# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no source problem that required a V2
edit.

The retained source change is in `repo/django/contrib/auth/tokens.py`:

- `_make_hash_value()` now appends the configured email component to the token
  hash input.
- It obtains the field name through `user.get_email_field_name()`.
- It falls back to `""` for missing or null-like email values.

## Trace to findings and proof obligations

The decision to keep the email in `_make_hash_value()` is justified by F1 and
PO1/PO3. F1 identifies the original bug: a token generated for
`foo@example.com` could still validate after the user changed to
`bar@example.com`. PO1 requires the email component in the hash input, and PO3
requires concrete email changes to reject old tokens.

The decision to use `get_email_field_name()` instead of hard-coding
`user.email` is justified by F2 and PO5. F2 shows that a custom user with
`EMAIL_FIELD = 'email_address'` would not be protected by a hard-coded email
lookup. PO5 requires honoring Django's configured email field hook.

The decision to keep the `getattr(..., '') or ''` fallback is justified by F3,
F4, and PO4. F3 traces the prompt's `AbstractBaseUser` compatibility concern:
not every user model has a concrete email attribute. PO4 requires token hashing
to remain defined for absent or null-like email. F4 records the only edge case:
null, missing, and empty email are collapsed to no concrete email address. The
audit accepted that because no public evidence requires distinguishing those
states for password reset tokens.

The decision not to add a compatibility fallback for pre-V1 tokens is justified
by F5 and PO1/PO3. F5 records that tokens generated without the email component
will no longer validate. The audit accepted that as necessary because preserving
those old tokens would also preserve the reported vulnerability: the old token
does not carry the old email value.

The decision not to alter timeout, secret, algorithm, password, last-login,
malformed-token, or absent-user behavior is justified by PO6. Those branches are
frame conditions over untouched code; V1 only changes the hash input state.

The decision not to change public signatures or callsites is justified by PO7
and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`. `make_token()`, `check_token()`, and
`_make_hash_value()` keep their existing call shapes.

## Verification status

The FVK proof is constructed, not machine-checked, as recorded in F6 and PO8.
No tests, Python code, or K commands were run. No test files were modified, and
no test removal is recommended unless the recorded K commands are run later and
`kprove` returns `#Top`.
