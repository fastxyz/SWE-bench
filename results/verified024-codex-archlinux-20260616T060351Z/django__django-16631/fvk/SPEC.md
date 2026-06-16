# FVK Spec: django__django-16631

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

This audit covers the V1 changes for auth session hashes during secret-key
rotation:

- `django.contrib.auth.base_user.AbstractBaseUser.get_session_auth_hash()`
- `AbstractBaseUser.get_session_auth_fallback_hash()`
- `django.contrib.auth._get_session_auth_fallback_hashes()`
- the session verification branch in `django.contrib.auth.get_user()`
- the same-user session-reuse branch in `django.contrib.auth.login()`

The model abstracts the concrete HMAC operation as `hmac(secret, password)`.
This keeps the property under verification visible: whether a stored
`_auth_user_hash` equals the current-key hash, a fallback-key hash, or neither.

## Intent Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | prompt | "SECRET_KEY_FALLBACKS is not used for sessions" | Existing auth sessions whose hashes were generated with a fallback key must remain authenticated during rotation. | Encoded by S3/S4 and K claim `getUser` fallback. |
| I2 | prompt/docs quote | Move the previous key to `SECRET_KEY_FALLBACKS`, then remove old values when ready to expire sessions and related artifacts. | Fallback keys are validation keys, not signing keys; old-key session hashes are valid while listed as fallbacks. | Encoded by S2/S4. |
| I3 | prompt | `salted_hmac()` defaults to `SECRET_KEY`; `get_session_auth_hash()` passed no `secret`. | Auth hash generation must be able to derive hashes with fallback secrets, not only the current secret. | Encoded by S1/S2. |
| I4 | public hint | "we should check fallback session hashes" | `auth.get_user(request)` must check fallback auth hashes before flushing. | Encoded by S4/S5. |
| I5 | public hint | "without any upgrading ... fallback keys are removed ... sessions will essentially be invalidated again" and "Maybe we could call update_session_auth_hash() when a fallback hash is valid" | Upgrading a fallback-valid session is not the minimum acceptance bug, but it is a justified improvement if performed only after validation. | Encoded by S4 and Finding F2. |
| I6 | docs | `get_session_auth_hash()` is based on `SECRET_KEY`; password changes invalidate sessions. | Fallback-key validation must not validate a session after the user's password hash changes. | Encoded by S5. |
| I7 | code contract/comment | `login()` flushes only when the existing session corresponds to another user or invalid auth state. | For the same user, a fallback-key hash is valid auth state during rotation and should not trigger a flush. | Encoded by S6. |
| I8 | compatibility | Existing custom users may define `get_session_auth_hash()` without a fallback method. | Fallback support must be optional and must not make such users error. | Encoded by S7. |

## State Model

- `CUR`: current `SECRET_KEY`.
- `FBS`: ordered values from `SECRET_KEY_FALLBACKS`.
- `PWD`: current value of the user's password field.
- `hmac(K, PWD)`: the session auth hash produced from secret `K` and password
  field `PWD`.
- `session_hash`: value stored in `_auth_user_hash`, or missing.
- `supports_fallbacks`: whether the user object provides
  `get_session_auth_fallback_hash()`.

The formal core is in:

- `fvk/mini-auth-session.k`
- `fvk/auth-session-spec.k`

## Behavioral Spec

S1. `get_session_auth_hash()` returns `hmac(CUR, PWD)` and preserves the
existing public API.

S2. `get_session_auth_fallback_hash()` yields exactly
`hmac(K, PWD)` for each `K` in `SECRET_KEY_FALLBACKS`. The order follows
settings order; correctness only requires membership, while order preserves the
documented "earlier key" performance expectation.

S3. In `get_user()`, if the stored session hash is `hmac(CUR, PWD)` and the
session references a configured backend and existing user, the user remains
authenticated and the stored hash is not changed for this reason.

S4. In `get_user()`, if the stored session hash is not the current hash but is
one of the fallback hashes generated from the current password field, the user
remains authenticated, the session key is cycled, and `_auth_user_hash` is
rewritten to `hmac(CUR, PWD)`.

S5. In `get_user()`, if the stored hash is missing, is neither current nor
fallback-valid, or was generated from a previous password field value, the
session is flushed and the returned user is anonymous.

S6. In `login()`, an existing same-user session with a current-key or
fallback-key hash is reusable; `login()` then stores `hmac(CUR, PWD)`. A
different user or an invalid same-user hash still flushes the existing session.

S7. For custom users without `get_session_auth_fallback_hash()`, fallback
checking is skipped and pre-existing `get_session_auth_hash()` behavior is
preserved.

## Adequacy Check

The formal claims paraphrase to the obligations above:

- Current-key hash authenticates.
- Fallback-key hash authenticates during rotation.
- Fallback-key hash in `get_user()` upgrades to the current hash.
- Password changes and invalid hashes still invalidate.
- Fallback support is optional for custom user objects.
- `login()` uses the same validity definition when deciding whether to flush a
  same-user session.

No formal claim is based only on legacy behavior. The only behavior beyond the
minimum issue sentence is S4's upgrade and S6's `login()` reuse; both are traced
to public intent or existing auth/session contracts in I5 and I7.

## Public Compatibility Audit

- Added public method: `AbstractBaseUser.get_session_auth_fallback_hash()`.
  Existing subclasses inherit it; subclasses that do not override it remain
  compatible.
- Added private helper:
  `django.contrib.auth._get_session_auth_fallback_hashes()`. This is not a
  public API.
- New virtual dispatch: callers use `get_session_auth_fallback_hash()` only via
  guarded `getattr()`. Custom user objects that implement only
  `get_session_auth_hash()` keep the previous behavior.
- Storage format: `_auth_user_hash` remains a string hash. On fallback match it
  is updated to the current-key hash; no new session keys or schema are added.
