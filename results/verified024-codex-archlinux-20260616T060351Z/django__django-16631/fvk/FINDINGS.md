# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Findings

### F1 - V1 addresses the reported root cause

Input/state: a user has password field `PWD`, current key `CUR`, fallback key
`OLD in SECRET_KEY_FALLBACKS`, and session `_auth_user_hash = hmac(OLD, PWD)`.

Observed before V1: `get_user()` compared the stored hash only with
`hmac(CUR, PWD)`, so the session was flushed and the user became anonymous.

Expected from public intent: the fallback-key session hash validates during
the rotation period.

V1 status: fixed by `AbstractBaseUser.get_session_auth_fallback_hash()` and the
fallback branch in `get_user()`. Covered by proof obligations O1-O4.

### F2 - Fallback-match upgrade is justified and not a blocking overreach

Input/state: same as F1, but the session receives traffic during the rotation
period and later `OLD` is removed from `SECRET_KEY_FALLBACKS`.

Risk considered: accepting fallback hashes without rewriting `_auth_user_hash`
would keep the session valid only until fallback removal, causing a second
invalidation. The public hint calls this out and suggests updating the session
hash, while also noting it might be separable from the minimum bug.

Expected from full intent: a fallback-valid session may be upgraded after it is
validated, because the session no longer "makes use of" the old key once the
stored hash is rewritten to the current hash.

V1 status: keep. The upgrade occurs only after a constant-time fallback match,
cycles the session key, and preserves session data. Covered by O4 and VC4.

### F3 - Extending fallback validity to `login()` is consistent with the auth contract

Input/state: an existing session belongs to the same user and stores
`hmac(OLD, PWD)` with `OLD` in fallbacks; `login(request, same_user)` is called
without `request.user` necessarily being evaluated first.

Observed before V1: `login()` treated the old-key hash as a mismatch and
flushed the same-user session.

Expected from intent: during rotation, an old-key hash in fallbacks is valid
auth state, not evidence of a password change or another user's session.

V1 status: keep. `login()` now reuses the same-user session for current or
fallback hash matches and still flushes for different users or invalid hashes.
Covered by O7-O8.

### F4 - Custom user compatibility remains intact

Input/state: a custom user object defines `get_session_auth_hash()` but does
not inherit `AbstractBaseUser` and has no fallback-hash method.

Observed before V1: Django supported this path by checking only
`hasattr(user, "get_session_auth_hash")`.

Expected from compatibility intent: adding fallback support must not make this
object raise an attribute error.

V1 status: fixed/kept. `_get_session_auth_fallback_hashes()` returns an empty
tuple when the fallback method is absent, so the legacy mismatch behavior is
preserved. Covered by O6.

### F5 - No further source defect found by the audit

The proof obligations cover current match, fallback match, invalid hash,
password-change invalidation, optional fallback support, and the `login()`
same-user reuse path. No obligation forced a code edit beyond V1.

Residual risk: the proof is constructed but not machine-checked, and no tests
were run per task instructions.

## Suggested Tests to Add Later

Do not modify tests in this benchmark. In a normal development pass, add tests
for:

- `AuthenticationMiddleware`/`get_user()` accepts an old-key auth hash when
  `SECRET_KEY_FALLBACKS` contains the old key.
- On that fallback match, `_auth_user_hash` is rewritten to the current hash
  and the session key is cycled.
- A password change still invalidates a session even if the old key is in
  fallbacks.
- A custom user implementing only `get_session_auth_hash()` does not error.
- `login()` does not flush a same-user session whose hash matches a fallback.
