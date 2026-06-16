# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Obligations

O1. Current auth hash generation.

- Spec: S1.
- Claim: `get_session_auth_hash(user)` is `hmac(CUR, PWD)`.
- Evidence: prompt points to `salted_hmac()` defaulting to current
  `SECRET_KEY`; V1 preserves that for the public method.
- Discharge: direct call from `get_session_auth_hash()` to
  `_get_session_auth_hash(secret=None)`, and `salted_hmac(..., secret=None)`
  retains current-key semantics.

O2. Fallback auth hash generation is complete.

- Spec: S2.
- Claim: for each `K` in `SECRET_KEY_FALLBACKS`,
  `get_session_auth_fallback_hash()` yields `hmac(K, PWD)`.
- Evidence: prompt requires fallbacks for sessions; docs describe fallback keys
  as old keys used for validation.
- Discharge: the generator iterates `settings.SECRET_KEY_FALLBACKS` and calls
  the same helper with `secret=fallback_secret`.

O3. `get_user()` accepts current-key hash.

- Spec: S3.
- Claim in `auth-session-spec.k`: current-key `getUser` claim.
- Discharge: current hash is computed once as `session_auth_hash`; if
  `constant_time_compare(session_hash, session_auth_hash)` succeeds, no flush
  branch executes.

O4. `get_user()` accepts and upgrades fallback-key hash.

- Spec: S4.
- Claim in `auth-session-spec.k`: fallback-key `getUser` claim.
- Discharge: after current comparison fails, the `any()` branch checks every
  fallback hash with `constant_time_compare`; on success it cycles the session
  key and writes the current hash.

O5. `get_user()` rejects invalid, missing, or password-stale hashes.

- Spec: S5.
- Claim in `auth-session-spec.k`: password-change invalidation claim.
- Discharge: missing hash is falsey; invalid current and fallback comparisons
  fall through to `request.session.flush()` and `user = None`. Since fallback
  hashes are generated from the current password field, a stored hash derived
  from an old password does not match.

O6. Custom user fallback support is optional.

- Spec: S7.
- Claim in `auth-session-spec.k`: `supports_fallback=false` claim.
- Discharge: `_get_session_auth_fallback_hashes()` uses guarded `getattr()`;
  absent fallback method returns `()`, preserving the previous mismatch path.

O7. `login()` reuses same-user sessions with valid current or fallback hashes.

- Spec: S6.
- Claim in `auth-session-spec.k`: fallback-key `login` reuse claim.
- Discharge: `session_auth_hash_verified` is true for current matches or any
  fallback match; the flush condition is false when the session user key equals
  `user.pk`.

O8. `login()` still flushes different-user or invalid same-user sessions.

- Spec: S6.
- Claim in `auth-session-spec.k`: different-user `login` claim.
- Discharge: the first disjunct `_get_user_session_key(request) != user.pk`
  still flushes another user's session; the second disjunct flushes same-user
  sessions only when neither current nor fallback hash validates.

## Verification Conditions

VC1. Fallback membership: `fallbackMatches(some(hmac(OLD, PWD)), PWD, FBS)` is
true iff `OLD` occurs in `FBS`. This is represented by the recursive
`fallbackMatches` function in `mini-auth-session.k`.

VC2. Password-change separation: for `OLDPWD != NEWPWD`, a stored
`hmac(K, OLDPWD)` must not validate against fallback hashes generated from
`NEWPWD`. This relies on the HMAC abstraction being injective enough for the
security property: a hash generated from a different password field is not
equal to a hash generated from the current password field.

VC3. Flush preservation: fallback acceptance must not weaken the existing
different-user session-flush condition. O8 covers the disjunction order.

VC4. Upgrade safety: `_auth_user_hash` is rewritten only on a validated current
user and fallback hash match. O4 covers the branch condition.

## Machine-Check Commands Not Run

```sh
kompile fvk/mini-auth-session.k --backend haskell
kast --backend haskell fvk/auth-session-spec.k
kprove fvk/auth-session-spec.k
```

Expected machine-checked result if the fragment and claims are accepted:
`#Top`.
