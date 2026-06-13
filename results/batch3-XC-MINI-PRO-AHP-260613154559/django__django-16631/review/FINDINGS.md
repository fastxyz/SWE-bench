# Code review — django__django-16631 (V1 fix)

Scope reviewed:
- `django/contrib/auth/base_user.py` — new `get_session_auth_fallback_hash()` and
  private `_get_session_auth_hash(secret=None)`; `get_session_auth_hash()` now
  delegates to the helper; added `from django.conf import settings`.
- `django/contrib/auth/__init__.py` — `get_user()` now checks fallback hashes and
  upgrades the session when a fallback matches.

Method: static reasoning only (no execution environment). Behavior is argued in
writing where a test would normally be run.

---

## F1 — Correctness against the reported issue: CONFIRMED
The issue is that after rotating `SECRET_KEY` (old value moved to
`SECRET_KEY_FALLBACKS`), all users are logged out because session verification in
`auth.get_user()` only compared against `user.get_session_auth_hash()`, which is
keyed solely with the current `SECRET_KEY` (`salted_hmac` defaults `secret` to
`settings.SECRET_KEY`, `crypto.py:26-27`). V1 adds a fallback path: when the
current-secret comparison fails, `get_user()` iterates
`user.get_session_auth_fallback_hash()` (one hash per `SECRET_KEY_FALLBACKS`
entry) and treats the session as valid on any constant-time match. This directly
resolves the reported logout-on-rotation behavior. **Correct.**

## F2 — Secondary concern from the public hint (hash upgrade): ADDRESSED
The hint warns that merely accepting a fallback match, without upgrading, would
re-invalidate every session once the fallback keys are eventually removed, and
suggests "call `update_session_auth_hash()` when a fallback hash is valid". V1
does the equivalent inline: on a fallback match it calls
`request.session.cycle_key()` and rewrites `HASH_SESSION_KEY` with the
current-secret hash (`session_auth_hash`). After one request each session is keyed
to the new secret, so removing the fallback later does not log the user out.
`update_session_auth_hash()` itself cannot be called here because it checks
`request.user == user`, and `request.user` is a `SimpleLazyObject` whose
evaluation re-enters `get_user()` (`middleware.py:13-16, 35`); the inline
`cycle_key()` + set is the correct equivalent and mirrors
`update_session_auth_hash()` (`__init__.py:242-244`). **Correct and desirable.**

## F3 — No regression on the default (non-rotation) path: CONFIRMED
`get_session_auth_hash()` → `_get_session_auth_hash()` → `_get_session_auth_hash(secret=None)`
→ `salted_hmac(key_salt, self.password, secret=None, algorithm="sha256")`. Because
`salted_hmac` resolves `secret is None` to `settings.SECRET_KEY`, the returned
digest is byte-for-byte identical to the previous implementation. The public
method's signature (zero args) and return value are unchanged. **No regression.**

## F4 — Edge cases / boundary conditions: CONFIRMED
- Missing/empty `session_hash`: `session_hash_verified = False`, then
  `if session_hash and any(...)` is False (short-circuit on falsy `session_hash`),
  so the `else` flushes and sets `user = None` — identical to the original
  behavior.
- Empty `SECRET_KEY_FALLBACKS` (the default `[]`): the generator yields nothing,
  `any(...)` over an empty iterator is `False`, so a non-matching session is
  flushed exactly as before. **No behavior change when the feature is unused.**
- No `UnboundLocalError`: `session_auth_hash` is referenced only inside
  `if session_hash and any(...)`. Reaching that branch requires `session_hash`
  truthy, which means the `else` branch (`session_auth_hash = user.get_session_auth_hash()`)
  already executed. Safe on every path.

## F5 — Idempotency and per-request caching: CONFIRMED
`auth.get_user` is memoized per request via `request._cached_user`
(`middleware.py:13-16`), so it normally runs once. Even if invoked again in the
same request, after the upgrade `request.session.get(HASH_SESSION_KEY)` returns
the new current-secret hash, so the primary comparison succeeds and `cycle_key()`
is not repeated. Idempotent.

## F6 — `cycle_key()` interaction with the session backend: CONFIRMED
`SessionBase.cycle_key()` (`sessions/backends/base.py:298-307`) creates a new key
while retaining data, deleting the old key. V1 calls `cycle_key()` first, then
sets `HASH_SESSION_KEY`; the set lands in the retained `_session_cache` and marks
the session modified, so the upgraded hash is persisted under the new key. The
session is already loaded at this point (we just read `BACKEND_SESSION_KEY` and
`HASH_SESSION_KEY`), so `cycle_key()` is safe. Writing to the session in
`get_user()` is already established behavior (the original code calls
`request.session.flush()`). Matches the pattern in `update_session_auth_hash()`.

## F7 — Subclass override of `get_session_auth_hash()`: ACCEPTABLE LIMITATION
`get_session_auth_hash()` is a documented customization point
(`docs/topics/auth/customizing.txt:720`). If a project overrides only that method
(not the new `get_session_auth_fallback_hash()`/`_get_session_auth_hash()`), the
inherited `get_session_auth_fallback_hash()` computes fallback hashes with the
base algorithm, which won't match a custom-derived stored hash; such users would
still be logged out on rotation. This is **not a regression** (custom-hash users
were always logged out on rotation pre-fix) and is overridable
(`get_session_auth_fallback_hash` is a clean extension point). The alternative —
giving the public `get_session_auth_hash(self, secret=None)` a secret parameter
and calling `self.get_session_auth_hash(secret=...)` from the fallback iterator —
is **worse**: existing overrides declared `def get_session_auth_hash(self):`
would raise `TypeError` (unexpected keyword `secret`) during rotation instead of
merely logging the user out. The private-helper design is the backwards-compatible
choice. **Keep V1.**

## F8 — `login()` path deliberately unchanged: JUSTIFIED
`login()` (`__init__.py:106-116`) flushes the session when the stored hash does
not match the current-secret hash, as session-fixation protection. During
rotation, a *re-login* by the same user would flush (losing pre-login session
data) rather than upgrade. This is acceptable and out of scope because: (a) the
reported bug is silent logout of already-authenticated users across requests
(the `get_user`/middleware path), not the explicit re-login path; (b) `login()`
unconditionally rewrites `HASH_SESSION_KEY` to the current-secret hash at
`__init__.py:140`, so the user ends up correctly logged in regardless; (c)
flushing on a hash mismatch at login is the existing, documented behavior (it also
happens when a password actually changed). Extending fallback logic into this
security-sensitive function would widen the patch for marginal UX benefit.
**Keep V1.**

## F9 — Consistency with codebase conventions: CONFIRMED
- Iterating `[current] + fallbacks` and matching with `constant_time_compare`
  mirrors `PasswordResetTokenGenerator.check_token()` (`tokens.py:69-76`).
- Passing `secret=` explicitly to `salted_hmac` mirrors
  `_make_token_with_timestamp()` (`tokens.py:88-93`).
- A leading-underscore private helper (`_get_session_auth_hash`) matches Django
  style (cf. `_get_secret`, `_make_token_with_timestamp`).
- `from django.conf import settings` placed in correct import-ordering position.

## F10 — Async path: CONFIRMED UNAFFECTED
`auser()` runs `sync_to_async(auth.get_user)` (`middleware.py:19-22`); all session
operations inside remain synchronous within the worker thread. No async-specific
concern is introduced.

## F11 — Documentation accuracy: NOW CONSISTENT
`docs/ref/settings.txt:2271-2286` states the secret key is used for "all sessions"
using the default `get_session_auth_hash()` and that values are invalidated only
when no longer in `SECRET_KEY` or `SECRET_KEY_FALLBACKS`. Pre-fix this was false
for sessions (they were invalidated immediately on rotation); V1 makes the docs
accurate. No documentation edit is required for correctness. (A 5.0 release note
would be appropriate in a real contribution but is non-testable and outside the
minimal-change scope — see control_notes.)

## F12 — Timing/security considerations: ACCEPTABLE
Each hash comparison uses `constant_time_compare`. The loop over fallbacks
short-circuits via `any(...)`, so total time leaks how many fallbacks were tried,
but the number/length of fallback keys is not secret and this matches the existing
`check_token()` loop. The per-key comparison (the security-relevant part) remains
constant time. The new password-derived fallback hashes are HMACs (no plaintext
secret exposure).

## F13 — Concurrent-request race on `cycle_key()`: PRE-EXISTING, OUT OF SCOPE
Two simultaneous in-flight requests from the same browser during the rotation
window could both `cycle_key()`, leaving the browser with whichever new cookie
arrives last. This race is inherent to `cycle_key()` and equally affects
`login()`/`update_session_auth_hash()`; V1 does not make it worse. Not addressed.

---

## Verdict
No correctness, regression, or convention defects found. V1 resolves the reported
issue (F1), addresses the hinted secondary drawback (F2), preserves all existing
behavior on the default and no-match paths (F3, F4), and is backwards compatible
(F7). The accepted limitations (F7, F8, F13) are justified and documented. **V1
stands; no code changes required.**
