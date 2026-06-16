# Baseline Notes

## Root cause

Authentication session hashes are derived from the user's password field with
`salted_hmac()`. `AbstractBaseUser.get_session_auth_hash()` used the default
secret, which means it always used the current `settings.SECRET_KEY`. During a
secret key rotation, sessions that stored `_auth_user_hash` values generated
with the old key could not be verified even when that old key was present in
`SECRET_KEY_FALLBACKS`.

The verification paths in `django.contrib.auth` also compared the stored
session hash only with the current-key hash. They had no way to accept hashes
derived from fallback secrets.

## Files changed

`repo/django/contrib/auth/base_user.py`

Added fallback session hash generation for `AbstractBaseUser`. The existing
`get_session_auth_hash()` API now delegates to a private helper that accepts an
optional secret, and `get_session_auth_fallback_hash()` yields hashes derived
from each configured `SECRET_KEY_FALLBACKS` value.

`repo/django/contrib/auth/__init__.py`

Added a small helper to read fallback auth hashes when a user object supports
them. Updated `get_user()` so an existing session hash is accepted if it matches
either the current secret or a fallback secret. When a fallback hash matches,
the session key is cycled and `_auth_user_hash` is rewritten with the current
secret's hash so the session can survive after the fallback key is later
removed. Updated `login()` to use the same fallback check when deciding whether
an existing same-user session should be flushed.

## Assumptions and rejected alternatives

I assumed the fallback behavior should apply to auth session hashes in the same
spirit as password reset tokens and signed session cookies: current-key hashes
remain preferred, while fallback-key hashes are accepted only for validation.

I kept fallback support optional for user objects. Custom user implementations
that define `get_session_auth_hash()` but do not inherit `AbstractBaseUser`
continue to behave as before instead of raising an attribute error.

I considered accepting fallback hashes without updating the stored session
hash, but rejected it because those sessions would be invalidated again as soon
as the fallback key is removed. Updating after a fallback match is targeted to
validated same-user sessions and mirrors the existing pattern of cycling the
session key when auth hash state changes.

I did not modify tests and did not run the test suite or project code, per the
benchmark instructions.
