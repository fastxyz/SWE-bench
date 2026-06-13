# Baseline notes — django__django-16631

## Issue

`SECRET_KEY_FALLBACKS` is not honored for user sessions. After rotating
`SECRET_KEY` (moving the previous value into `SECRET_KEY_FALLBACKS` as the docs
recommend), every already-authenticated user is logged out.

## Root cause

A user's session is validated in `django.contrib.auth.get_user()`. It compares
the `_auth_user_hash` stored in the session against
`user.get_session_auth_hash()`:

```python
session_hash_verified = session_hash and constant_time_compare(
    session_hash, user.get_session_auth_hash()
)
if not session_hash_verified:
    request.session.flush()
    user = None
```

`AbstractBaseUser.get_session_auth_hash()` computes an HMAC of the password via
`salted_hmac(...)` **without** passing a `secret`, so `salted_hmac` falls back to
`settings.SECRET_KEY` (see `django/utils/crypto.py:26-27`). When the secret is
rotated, the freshly computed hash is keyed with the *new* `SECRET_KEY`, while
the session cookie still holds a hash keyed with the *old* secret. The comparison
fails, the session is flushed, and the user is logged out — `SECRET_KEY_FALLBACKS`
is never consulted.

This mirrors a gap that `PasswordResetTokenGenerator.check_token()` already
handles correctly: it verifies against `[self.secret, *self.secret_fallbacks]`.
Sessions had no equivalent fallback handling. (The hint cites the regression
origin commit `0dcd549bbe36c060f536ec270d34d9e7d4b8e6c7`.)

## Changes

### `django/contrib/auth/base_user.py`
- Added `from django.conf import settings`.
- Refactored `get_session_auth_hash()` to delegate to a new private
  `_get_session_auth_hash(secret=None)` helper, which forwards `secret` to
  `salted_hmac`. `get_session_auth_hash()` keeps its original behavior (uses the
  current `SECRET_KEY`).
- Added `get_session_auth_fallback_hash()`, a generator yielding the session auth
  hash computed with each secret in `settings.SECRET_KEY_FALLBACKS`.

This follows the same `_secret` / `secret_fallbacks` shape used by
`PasswordResetTokenGenerator` and keeps the public method signature unchanged.

### `django/contrib/auth/__init__.py` (`get_user`)
- When the session hash does not match the hash computed with the current
  `SECRET_KEY`, the code now also checks the hashes produced from
  `SECRET_KEY_FALLBACKS` via `user.get_session_auth_fallback_hash()`.
- If a fallback hash matches, the session is treated as valid **and upgraded**:
  `request.session.cycle_key()` is called and `_auth_user_hash` is rewritten with
  the current-secret hash (`session_auth_hash`). This directly addresses the
  drawback raised in the public hint — without upgrading, sessions would be
  invalidated again once the fallback keys are eventually removed. After one
  successful request the cookie is keyed with the new secret, so later requests
  verify against `SECRET_KEY` directly.
- If no current or fallback hash matches, the original behavior is preserved:
  flush the session and return `AnonymousUser`.

Edge cases preserved:
- Empty/missing `session_hash` → `session_hash_verified = False`, the
  `session_hash and any(...)` guard is False, so the session is flushed exactly
  as before.
- Empty `SECRET_KEY_FALLBACKS` (the default) → the generator yields nothing,
  `any(...)` is False, behavior is identical to before the change.
- `session_auth_hash` is only referenced inside the `if session_hash and ...`
  branch, and it is assigned in the `else` branch that runs whenever
  `session_hash` is truthy, so there is no `UnboundLocalError`.

## Assumptions and rejected alternatives

- **Only `get_user()` needs the fallback check.** The reported bug is about
  already-authenticated users being logged out, which flows through
  `AuthenticationMiddleware` → `auth.get_user(request)`. I deliberately left the
  `login()` session-fixation comparison (`__init__.py:107-111`) unchanged: that
  path is a fresh re-authentication that rewrites `_auth_user_hash` to the
  current secret anyway, and flushing stale anonymous session data there is the
  existing, acceptable behavior. Changing it would widen the patch without
  fixing the reported problem.

- **Upgrade the hash vs. just accept it.** I chose to upgrade (`cycle_key()` +
  rewrite the hash) rather than merely accepting the fallback match. Accepting
  without upgrading would re-invalidate every session the moment the fallback
  keys are removed — the exact secondary problem called out in the hint. Cycling
  happens at most once per session during the rotation window, since subsequent
  requests match the current secret directly.

- **Iterating fallbacks is not constant-time across the list length.** This is
  intentional and matches the existing `PasswordResetTokenGenerator.check_token`
  pattern; each individual comparison still uses `constant_time_compare`, and the
  number of fallback keys is not secret.

- **No documentation change made.** The existing `SECRET_KEY_FALLBACKS` docs
  describe the now-correct behavior (rotating the key keeps sessions valid), so
  they require no edit. The task scope is the code fix.
