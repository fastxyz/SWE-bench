# Control notes — django__django-16631 (audit of V1)

## Outcome
After a systematic review (see `review/FINDINGS.md`), **V1 stands unchanged**. The
review found no correctness, regression, or convention defects, so no source edits
were made in this pass. Below, every decision is traced to specific findings.

## Files in the fix (unchanged from V1)
- `django/contrib/auth/base_user.py`
- `django/contrib/auth/__init__.py`

## Decisions and their justification

### 1. Keep the core fallback check in `get_user()` as written — F1
The fallback iteration over `user.get_session_auth_fallback_hash()` with
`constant_time_compare` correctly fixes the reported "all users logged out on
secret rotation" bug. Verified against the issue description and the
`salted_hmac` default-secret behavior. No change needed.

### 2. Keep the session-hash *upgrade* (`cycle_key()` + rewrite) — F2
The public hint explicitly calls out that accepting a fallback match without
upgrading would re-invalidate sessions once fallbacks are removed, and suggests
upgrading. V1's inline `cycle_key()` + `HASH_SESSION_KEY = session_auth_hash`
implements exactly this and is the correct equivalent of
`update_session_auth_hash()` (which can't be called directly here because it
dereferences `request.user`, re-entering `get_user`). Kept.

### 3. Keep `get_session_auth_hash()`'s zero-argument signature; route through a
private `_get_session_auth_hash(secret=None)` — F3, F7
This preserves the documented public API and produces byte-identical output on the
default path (F3). Crucially, it is backwards compatible with existing subclass
overrides: the rejected alternative of adding a `secret` parameter to the public
method would make `get_session_auth_fallback_hash()` call
`self.get_session_auth_hash(secret=...)`, raising `TypeError` on legacy overrides
declared without that parameter (F7). The private-helper design degrades
gracefully (custom-hash users are simply not auto-upgraded, same as pre-fix) and
leaves a clean override point. Kept.

### 4. Keep `get_session_auth_fallback_hash()` as a generator — F1, F9, F12
Lazy generation lets `any(...)` short-circuit on the first match and mirrors the
`[secret, *fallbacks]` iteration style of `PasswordResetTokenGenerator`
(F9/F12). No change.

### 5. Leave the edge-case handling as-is — F4
Empty `session_hash`, empty `SECRET_KEY_FALLBACKS`, and the no-`UnboundLocalError`
guarantee were all verified by static reasoning. The new code reduces to the
original behavior whenever the feature is unused, so no defensive rewrites were
warranted.

### 6. Do NOT modify `login()` — F8
The reported bug is silent cross-request logout via the middleware/`get_user`
path, not the explicit re-login path. `login()` already rewrites the hash to the
current secret and its flush-on-mismatch is established session-fixation
behavior. Extending fallback logic there would enlarge a security-sensitive
function for marginal benefit. Deliberately left untouched.

### 7. Do NOT change documentation or add a release note — F11
The existing `SECRET_KEY_FALLBACKS`/session docs become *accurate* with this fix
(previously they overstated session persistence across rotation), so no doc edit
is needed for correctness. A 5.0 release note would suit a real contribution but
is non-testable and outside the minimal-change scope, so it was omitted.

### 8. Accept the documented out-of-scope limitations — F7, F13
The custom-`get_session_auth_hash` subclass case (F7) and the inherent
`cycle_key()` concurrent-request race (F13) are pre-existing or unavoidable
trade-offs, not regressions introduced by V1. They are recorded in the findings
rather than "fixed" with speculative complexity.

## Confidence
Reasoning-only (no test execution available, per task constraints). The change is
small, localized, mirrors two established patterns in the same package
(`PasswordResetTokenGenerator`, `update_session_auth_hash`), and preserves all
prior behavior on the default and no-match paths — giving high confidence that V1
is correct and safe.
