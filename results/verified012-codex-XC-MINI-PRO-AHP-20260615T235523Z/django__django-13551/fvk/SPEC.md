# FVK Specification

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Target

The audited unit is `PasswordResetTokenGenerator` in
`repo/django/contrib/auth/tokens.py`, with focus on:

- `_make_hash_value(user, timestamp)`
- `_make_token_with_timestamp(user, timestamp, legacy=False)`
- `check_token(user, token)`

There are no loops in the target. The proof is a straight-line reachability
argument over token construction and token checking.

## Public Intent Ledger

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The critical
entries are:

- E1: an unused reset token must be rejected after the user's concrete email
  address changes.
- E2: the user's email address belongs in `_make_hash_value()`.
- E3: `AbstractBaseUser` does not force every user to have a concrete email
  attribute.
- E4/E5: `get_email_field_name()` is Django's public hook for selecting custom
  email fields.
- E6/E7: existing token validity, timeout, secret, and legacy-algorithm behavior
  remain frame conditions.

## Formal Domain

The proof domain is a well-formed password-reset token generated from an
`AbstractBaseUser`-style user state:

- `pk`
- `password`
- `last_login`, represented after Django's existing microsecond truncation
- `timestamp`
- configured email-field name from `get_email_field_name()`
- configured email value, if present

The email component is:

- the value of the configured email field when a concrete value is present;
- `""` when the configured field is absent or null-like.

This domain intentionally covers the issue's sequence and the no-email custom
user compatibility concern. Malformed tokens, missing users, and expired tokens
remain existing guarded branches in `check_token()` and are preserved as frame
conditions rather than reimplemented by the V1 change.

## Claims

C1. Hash construction:

For any in-domain user `U` and timestamp `T`,
`_make_hash_value(U, T)` includes:

`str(U.pk)`, `U.password`, normalized `last_login`, `str(T)`, and the configured
email component.

C2. Same-state validation:

For an unexpired token generated from user state `U` at timestamp `T`,
`check_token(U, token)` succeeds when secret, algorithm, and user state are
unchanged.

C3. Email-change rejection:

For an unexpired token generated from user state `U_old` at timestamp `T`,
checking against `U_new` fails when all modeled state is equal except the
configured concrete email component and
`email_component(U_old) != email_component(U_new)`.

C4. Custom email field:

If `U.get_email_field_name()` returns a custom field such as `email_address`,
the hash uses that field's value, not a hard-coded `email` attribute.

C5. No-email compatibility:

If the configured email field is absent or null-like, the hash uses `""` for the
email component and token generation remains defined.

C6. Frame conditions:

The V1 patch does not change public method signatures, token parsing, timeout
comparison, constant-time comparison, secret handling, legacy SHA-1 comparison,
or the password and last-login invalidation mechanisms already present in the
source.
