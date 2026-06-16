# Public Evidence Ledger

E1. Source: `benchmark/PROBLEM.md`

Quote: "foo@... account changes their email address" and "The password reset
email's token should be rejected at that point, but in fact it is allowed."

Obligation: Tokens generated before a concrete email-address change are invalid
after that change.

Status: encoded by PO3 and the `EMAIL-CHANGE-REJECTED` K claim.

E2. Source: `benchmark/PROBLEM.md`

Quote: "The fix is to add the user's email address into
PasswordResetTokenGenerator._make_hash_value()"

Obligation: `_make_hash_value()` must include the email component in the HMAC
input.

Status: encoded by PO1 and the `HASH-USES-CONFIGURED-EMAIL` K claim.

E3. Source: `benchmark/PROBLEM.md`

Quote: "Nothing forces a user to even have an email as per AbstractBaseUser."

Obligation: The fix must not require a concrete `email` attribute to exist on
all user objects.

Status: encoded by PO4 and the `MISSING-EMAIL-DEFINED` K claim.

E4. Source: `repo/docs/topics/auth/customizing.txt`

Quote: "`get_email_field_name()` Returns the name of the email field specified
by the `EMAIL_FIELD` attribute. Defaults to `'email'` if `EMAIL_FIELD` isn't
specified."

Obligation: The configured email field name is the public hook for custom user
models.

Status: encoded by PO1, PO5, and the configured-field K claims.

E5. Source: `repo/django/contrib/auth/forms.py`

Quote: `email_field_name = UserModel.get_email_field_name()` and
`user_email = getattr(user, email_field_name)`.

Obligation: Password-reset email delivery already uses the configured email
field; token hashing should use the same public field selection.

Status: encoded by PO5.

E6. Source: `repo/django/contrib/auth/tokens.py`

Quote: `make_token()` returns "a token that can be used once to do a password
reset" and `check_token()` checks "that a password reset token is correct for a
given user."

Obligation: Generated tokens should validate for the same unchanged user while
incorrect, tampered, expired, or state-stale tokens should not.

Status: encoded by PO2, PO3, and PO6.

E7. Source: `repo/tests/auth_tests/test_tokens.py`

Quote: public tests assert generated tokens validate, timeout boundaries are
enforced, different secrets fail, and the legacy SHA-1 algorithm path validates
tokens generated with the same state.

Obligation: Existing token behavior unrelated to the new email state should be
preserved.

Status: encoded as frame obligation PO6. No test file was modified.
