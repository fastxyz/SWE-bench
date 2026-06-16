# FVK Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Adequacy Gate

The public intent requires auth session hashes generated with previous secret
keys to validate while those keys are listed in `SECRET_KEY_FALLBACKS`. The
formal claims do not prove legacy behavior; they prove branch behavior against
that intent:

- current-key hash authenticates;
- fallback-key hash authenticates and upgrades in `get_user()`;
- invalid and password-stale hashes still flush;
- fallback support is optional for custom users;
- `login()` applies the same valid-hash definition when deciding whether to
  flush a same-user session.

The only non-minimal behavior is the upgrade on fallback match. It is supported
by the public hint and does not contradict the docs because the stored session
hash no longer uses the old key after upgrade.

## Constructed Proof Sketch

P1. `AbstractBaseUser.get_session_auth_hash()`.

Symbolically execute the method body. It returns
`self._get_session_auth_hash()` with `secret=None`. `_get_session_auth_hash()`
calls `salted_hmac(key_salt, self.password, secret=None, algorithm="sha256")`.
By Django's `salted_hmac()` contract, `secret=None` uses `settings.SECRET_KEY`.
Therefore the result is `hmac(CUR, PWD)`, proving O1.

P2. `AbstractBaseUser.get_session_auth_fallback_hash()`.

Symbolically execute the generator over `settings.SECRET_KEY_FALLBACKS`. For
each fallback secret `K`, the yielded value is
`self._get_session_auth_hash(secret=K)`, which expands to `hmac(K, PWD)`.
The loop is a finite iterator over the configured list; no filtering or
reordering occurs. This proves O2.

P3. `_get_session_auth_fallback_hashes(user)`.

Case split on whether `user` has `get_session_auth_fallback_hash`.

- If absent, the helper returns `()`. Fallback matching is false, preserving
  legacy behavior for custom users. This proves O6.
- If present, the helper returns that method's iterable. For
  `AbstractBaseUser`, P2 supplies the fallback hash list.

P4. `get_user()` current-hash branch.

Assume the backend is configured, `backend.get_user(user_id)` returns `user`,
and `session_hash = hmac(CUR, PWD)`. The method computes
`session_auth_hash = user.get_session_auth_hash() = hmac(CUR, PWD)` by P1.
`constant_time_compare(session_hash, session_auth_hash)` is true, so the
`if not session_hash_verified` branch is skipped. The function returns the
loaded user. This proves O3.

P5. `get_user()` fallback branch.

Assume `session_hash = hmac(OLD, PWD)`, `OLD in SECRET_KEY_FALLBACKS`, and
`OLD != CUR`. The current comparison in P4 is false. The fallback iterator from
P2 contains `hmac(OLD, PWD)`, so the `any(constant_time_compare(...))` branch
is true. The method executes `request.session.cycle_key()` and writes
`request.session[HASH_SESSION_KEY] = hmac(CUR, PWD)`, then returns the loaded
user. This proves O4 and Finding F2's safety condition.

P6. `get_user()` invalid or password-stale branch.

If `session_hash` is missing, the first comparison is false and the fallback
branch is not entered because it is guarded by `session_hash`. If the hash is
neither current nor generated from a fallback key with the current password
field, all comparisons fail. The method flushes the session and sets
`user = None`, causing the final return to be `AnonymousUser()`. This proves
O5.

P7. `login()` same-user fallback branch.

Assume the existing session user key equals `user.pk` and the stored hash is
`hmac(OLD, PWD)` with `OLD in SECRET_KEY_FALLBACKS`. The current comparison is
false, but the fallback `any()` comparison is true by P2. The flush condition
is false because the user id matches and `session_auth_hash_verified` is true.
The method then writes the normal login session keys, including
`HASH_SESSION_KEY = hmac(CUR, PWD)`. This proves O7.

P8. `login()` different-user or invalid-hash branch.

If the stored user key differs from `user.pk`, the first disjunct of the flush
condition remains true regardless of fallback hashes. If the stored user key
matches but neither current nor fallback comparison succeeds, the second
disjunct is true. In both cases V1 preserves the existing flush behavior before
writing the new login session keys. This proves O8.

## Residual Risk

- The proof is constructed, not machine-checked.
- The K fragment abstracts HMAC as `hmac(secret, password)` and assumes unequal
  password field values do not collide for the session-auth security property.
- Termination is not a meaningful extra obligation here: the audited branches
  are finite except for iterating the finite configured fallback list.
- No public or hidden tests were run, by instruction.

## Test-Redundancy Recommendation

No test files were edited. Because the proof was not machine-checked, no tests
should be removed. If the K claims are later machine-checked, point tests that
only assert the current/fallback/invalid branch behavior covered by O3-O8 would
be candidates for redundancy, while integration tests for middleware, session
backends, and signed cookies should be kept.

## Reproduce the Machine Check Later

```sh
kompile fvk/mini-auth-session.k --backend haskell
kast --backend haskell fvk/auth-session-spec.k
kprove fvk/auth-session-spec.k
```

Expected machine-checked result if the fragment and claims are accepted:
`#Top`.
