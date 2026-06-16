# Baseline Notes

## Root cause

`PasswordResetTokenGenerator._make_hash_value()` generated the HMAC input from
the user's primary key, password hash, last login timestamp, and token
timestamp. It did not include the user's email address, so a password reset link
created for one email address could remain valid after that user changed their
email, as long as the password, last login, and timeout state did not invalidate
the token.

## Changed files

`repo/django/contrib/auth/tokens.py`

- Added the current email field value to the password reset token hash input.
- Used `user.get_email_field_name()` so custom user models that rename their
  email field participate correctly.
- Used `getattr(..., '') or ''` so custom user models without an email field, or
  with a null-like email value, continue to produce tokens instead of raising an
  attribute or type error.
- Updated the method comment to document email changes as token-invalidating
  user state.

## Assumptions and alternatives considered

I assumed the intended behavior is that any change to the user's configured
email field after token creation should invalidate the old reset token.

I considered hard-coding `user.email`, but rejected it because Django supports
custom user models and already exposes `get_email_field_name()` for this exact
field lookup in the password reset form.

I considered adding a new model-level token hook, similar to
`get_session_auth_hash()`, but rejected it as larger than necessary for this
issue. The existing token generator can solve the reported bug directly while
remaining compatible with custom email field names.

I considered requiring every user model to define an email attribute, but
rejected it because `AbstractBaseUser` does not require one and password reset
token generation should not fail solely because a custom user model omits email.
