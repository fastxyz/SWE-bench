# FINDINGS — django__django-16631 (FVK audit of the V1 fix)

Plain-language findings, each as `input → observed vs expected`. Findings are
non-blocking advice. "Observed" = behavior of the **V1 code currently in
`repo/`**. A clean spec was writable for the whole fix (`fvk/SPEC.md`), which is
itself a positive signal (benefit #2: spec-difficulty would have meant a bug).

Legend: ✅ confirmed-correct · ⚠️ residual risk (accepted) · 📐 scope decision ·
🔎 root-cause restatement.

---

## 🔎 F0 — The original (V0/pre-fix) bug, restated as the contract gap
- **input:** user logged in before rotation (cookie `_auth_user_hash =
  H3(salt,pwd,old_key)`); admin sets `SECRET_KEY = new_key`,
  `SECRET_KEY_FALLBACKS = [old_key]`; user makes any request.
- **observed (V0):** `get_user` compares the stored hash only against
  `H3(salt,pwd,new_key)`; mismatch ⇒ `session.flush()`, user logged out.
- **expected (intent I1):** stored hash also checked against the fallback-key
  hash `H3(salt,pwd,old_key)` ⇒ session kept.
- **status:** fixed by V1 — `(GETUSER)` now yields `UPGRADE` (not `FLUSH`) on
  this input. See PROOF_OBLIGATIONS PO2.

## ✅ F1 — Refactor preserves every existing session hash (backward compat)
- **input:** any user; `SECRET_KEY` unchanged; cookie minted before the upgrade.
- **observed (V1):** `get_session_auth_hash()` → `_get_session_auth_hash()` →
  `salted_hmac(salt, pwd, secret=None, …)`. Pre-fix code called
  `salted_hmac(salt, pwd, …)` with `secret` **omitted**. In
  `django/utils/crypto.py:26` both omission and `secret=None` hit
  `if secret is None: secret = settings.SECRET_KEY`.
- **expected:** byte-identical digest ⇒ no currently-valid cookie is
  invalidated by deploying the fix.
- **status:** confirmed correct. Discharged by `(HASH-EQ)` (PO1). This is the
  single most important non-regression: a careless refactor here would have
  re-introduced the very mass-logout the ticket reports.

## ✅ F2 — `session_auth_hash` is always defined where it is read (no `UnboundLocalError`)
- **input:** `session_hash` absent/empty (`None` or `""`) and verification fails.
- **observed (V1):** `session_auth_hash` is assigned only in the `else` of
  `if not session_hash:` (`__init__.py:205`). The later read at line 218
  (`request.session[HASH_SESSION_KEY] = session_auth_hash`) sits inside
  `if session_hash and any(...):`. Python `and` short-circuits on the falsy
  `session_hash`, so line 218 is unreachable whenever `session_auth_hash` is
  unbound.
- **expected:** no `NameError`/`UnboundLocalError` on any path.
- **status:** confirmed correct — **but load-bearing**: the guard order
  (`session_hash and …`, not `any(...) and session_hash`) is what makes it
  safe. PROOF_OBLIGATIONS PO4. (Reordering the conjunction would be a real bug;
  flagged for ITERATION_GUIDANCE so a future edit doesn't "tidy" it.)

## ✅ F3 — Degenerate inputs reduce to the pre-fix behavior
- **input (a):** `SECRET_KEY_FALLBACKS = []` (the default).
  - observed: `get_session_auth_fallback_hash()` yields nothing ⇒
    `any(empty) = False` ⇒ `FLUSH`. expected: identical to pre-fix. ✅
- **input (b):** `session_hash` empty/`None`.
  - observed: `session_hash_verified = False`; `if session_hash and …` is
    falsy ⇒ `FLUSH`; the generator is **never called**. expected: identical to
    pre-fix, and no needless hashing. ✅
- **status:** confirmed correct. Discharged by substituting `FB = []` /
  `H = eps` into `(GETUSER)` (PO5, PO6).

## ✅ F4-resolved-as-✅ … see ⚠️ F4 below for the one residual.

## ✅ F5 — Upgrade-on-fallback makes rotation convergent (the hint, addressed)
- **input:** session validated via a fallback (F0's input), then a *second*
  request; later the admin removes the fallback.
- **observed (V1):** first request takes `UPGRADE`: `cycle_key()` +
  `request.session[HASH_SESSION_KEY] = session_auth_hash` (the current-key
  hash). Second request: stored hash now equals the current-key hash ⇒ `KEEP`
  (no scan, no second cycle). When fallbacks are later removed, the cookie is
  already current-key ⇒ **not** re-invalidated.
- **expected (intent I3):** exactly this; the public hint warned that without
  upgrading, "all of those sessions will essentially be invalidated again" once
  fallbacks are removed.
- **status:** confirmed correct & convergent (idempotent after one request).
  PROOF_OBLIGATIONS PO3, PO9.

## ⚠️ F4 — A duck-typed user with `get_session_auth_hash` but **without**
`get_session_auth_fallback_hash` would raise `AttributeError` on the fallback path
- **input:** a non-`AbstractBaseUser` object that nonetheless defines
  `get_session_auth_hash` (so `hasattr(user, "get_session_auth_hash")` is True),
  whose stored hash does not match the current key (e.g. right after a password
  change), with a non-empty `session_hash`.
- **observed (V1):** line 215 evaluates
  `user.get_session_auth_fallback_hash()` directly; the missing method raises
  `AttributeError` instead of the pre-fix graceful `FLUSH`.
- **expected:** graceful flush (logout), as before.
- **assessment — accepted, not changed.** Reasons, traced to the codebase:
  1. `get_session_auth_fallback_hash` is defined on **`AbstractBaseUser`**
     (`base_user.py:141`), the documented required base for *all* custom user
     models; a grep of `repo/` shows `get_session_auth_hash` is defined **only**
     there — no first-party code defines it standalone.
  2. The pre-existing code at `__init__.py:205` already calls
     `user.get_session_auth_hash()` **directly** (not via `getattr`) inside the
     same `hasattr` block, i.e. it already treats the auth-hash protocol as
     all-or-nothing once `get_session_auth_hash` is present. V1 stays consistent
     with that established contract.
  3. Adding a defensive `hasattr(user, "get_session_auth_fallback_hash")` guard
     would change behavior for an unsupported object only, and would diverge
     from the minimal paired-method design. Rejected for now; raised as an
     UltimatePowers question in ITERATION_GUIDANCE.

## ⚠️ F6 — Fallback iteration is not constant-time in the *number* of fallbacks
- **input:** stored hash matching the k-th fallback vs the first fallback.
- **observed (V1):** each candidate is compared with `constant_time_compare`,
  but `any(...)` short-circuits, so wall-clock time grows with the index of the
  first match / the list length.
- **expected / assessment — accepted.** The fallback **count** is server
  configuration, not a secret; per-candidate comparison is constant-time. This
  is identical to `PasswordResetTokenGenerator.check_token`
  (`tokens.py:69-74`), which loops `for secret in [self.secret,
  *self.secret_fallbacks]` and `break`s. Intent I5 (security parity) is met.

## 📐 F7 — `login()` is intentionally **not** made fallback-aware
- **input:** a user re-authenticating (`auth.login`) while still holding a
  pre-rotation session cookie.
- **observed (V1):** `login()` (`__init__.py:106-116`) still compares the
  existing session hash against the **current-key** hash only; a mismatch
  `session.flush()`es the pre-login session, then line 140 writes the
  current-key hash.
- **expected / assessment — deliberate scope.** This is the *active login*
  path, not the *passive validation* path the ticket is about. The flush there
  is the **session-fixation guard** ("avoid reusing another user's session");
  the user is re-authenticating and ends up correctly logged in with a
  current-key hash regardless. Making it fallback-aware would only preserve
  pre-login anonymous session data during rotation — a minor UX nicety,
  unrelated to the reported logout-of-already-authenticated-users bug, and it
  touches security-sensitive code. Out of scope; noted in ITERATION_GUIDANCE.

## ✅ F8 — A clean spec exists for the whole fix (no spec-difficulty bug signal)
- Every branch of `get_user`'s verification block maps to one of three
  mutually-exclusive, exhaustive cases (`KEEP`/`UPGRADE`/`FLUSH`) with a clean
  membership predicate and **no** awkward case splits, no invented side
  condition, no non-universal postcondition. Per the FVK doctrine
  ("spec-difficulty = bug signal"), the *absence* of difficulty here is positive
  evidence that V1 is correct.

---

## Proof-derived findings from `/verify`

- **PD1 (from `(HASH-EQ)`):** the proof needs `resolve(eps) = SK` on *both*
  paths — confirming F1; the only way to break backward compat would be passing
  a non-`None` secret in `_get_session_auth_hash`'s default, which V1 does not.
- **PD2 (from `(SCAN-LOOP)`):** the loop's closed form is `F or inList(H, FB)`;
  the body-taken branch needs only `or`-associativity (Z3) plus `inList`'s cons
  equation — no nonlinear/inductive VC beyond definitional unfolding, so this
  stays inside the bundled tier (unlike sortedness/permutation). No escalation.
- **PD3 (from `(GETUSER)`):** substituting `FB = []` must collapse the
  postcondition to the pre-fix contract; it does (the `UPGRADE` disjunct's
  `inList(H, [])` is `false`). This is the machine-checkable statement of
  backward compatibility (F3a). No obstacle ⇒ no code change required.
