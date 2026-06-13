# ITERATION GUIDANCE — django__django-16631

Feedback package for the next generate→formalize→verify pass. Each entry:
**Evidence · Classification · UltimatePowers question · Recommended change ·
Tests**, per `fvk_materials/commands/verify.md` Step 3.

## Verdict: **V1 STANDS (unchanged).**

The audit discharged PO1–PO10 (`fvk/PROOF_OBLIGATIONS.md`) and produced a clean,
exhaustive three-case spec for `get_user` with no spec-difficulty signal
(FINDINGS F8). The fix realizes intents I1–I5: fallback acceptance (F0/PO2),
upgrade-on-fallback convergence (F5/PO9), backward compatibility (F1/PO1, PO5),
empty-input safety (F3/PO6), and security parity (F6). No correctness obstacle
surfaced, so no source edit is warranted. The remaining entries are accepted
risks / scope decisions, recorded for a future maintainer — not defects to fix
now.

---

### G1 — Backward-compat keystone (confirm, don't change)
- **Evidence:** `(HASH-EQ)` / PO1; `base_user.py:145-152` passes `secret=None`;
  `django/utils/crypto.py:26`.
- **Classification:** confirmed-correct invariant.
- **UltimatePowers question:** none.
- **Recommended change:** **none.** Guard against regressions: never give
  `_get_session_auth_hash`'s `secret` a non-`None` default — that would silently
  invalidate every existing session.
- **Tests:** keep a "current-key cookie still validates after deploy" test.

### G2 — Conjunct order is load-bearing (don't "tidy")
- **Evidence:** PO4 / FINDINGS F2; `__init__.py:213` `if session_hash and
  any(...)`.
- **Classification:** needed code-shape invariant (definite assignment).
- **UltimatePowers question:** none.
- **Recommended change:** **none.** A future refactor must keep `session_hash`
  as the *first* conjunct (and must not hoist the `session_auth_hash` read above
  its `else`-branch assignment), or it reintroduces a possible
  `UnboundLocalError`/`NameError` on the empty-hash path.
- **Tests:** keep an "empty/absent `_auth_user_hash` ⇒ logged out, no error"
  test (out-of-happy-path, cheap).

### G3 — Duck-typed user missing `get_session_auth_fallback_hash` (accepted)
- **Evidence:** FINDINGS F4; `__init__.py:215` calls
  `user.get_session_auth_fallback_hash()` directly; method defined only on
  `AbstractBaseUser` (`base_user.py:141`).
- **Classification:** accepted robustness gap (out of verified domain).
- **UltimatePowers question:** *"Should `get_user` defensively fall back to a
  graceful flush for a user object that defines `get_session_auth_hash` but not
  `get_session_auth_fallback_hash`, or is `AbstractBaseUser` the contract?"*
- **Recommended change (only if the answer is "be defensive"):** add a guard
  `session_hash and hasattr(user, "get_session_auth_fallback_hash") and
  any(...)`. **Rejected for V1** because the method ships on `AbstractBaseUser`
  (Django's required base) and the surrounding code already calls
  `get_session_auth_hash()` unconditionally once present — adding the guard would
  diverge from the minimal paired-method design with no benefit to any supported
  model.
- **Tests:** keep any test exercising a non-`AbstractBaseUser` auth object (it
  pins out-of-domain behavior).

### G4 — Fallback scan not constant-time in list length (accepted)
- **Evidence:** FINDINGS F6; `__init__.py:213-216`; parity with
  `tokens.py:69-74`.
- **Classification:** accepted security property (count is not secret).
- **UltimatePowers question:** *"Is the number of `SECRET_KEY_FALLBACKS`
  considered sensitive?"* (Expected: no.)
- **Recommended change:** **none.** Matches `PasswordResetTokenGenerator`.
- **Tests:** none functional; timing is outside the functional contract.

### G5 — `login()` not made fallback-aware (scope)
- **Evidence:** FINDINGS F7; `__init__.py:106-116`.
- **Classification:** deliberate scope decision.
- **UltimatePowers question:** *"During rotation, should an explicit re-login
  preserve pre-login (anonymous) session data when the old cookie validates
  against a fallback, or is flushing it acceptable?"*
- **Recommended change (only if "preserve"):** mirror the fallback check in
  `login()`'s session-fixation comparison — but this touches the
  session-reuse/fixation guard, so it needs its own spec + review. Out of scope
  for the reported bug (passive validation), where V1 is complete.
- **Tests:** keep existing `login()` session-fixation tests unchanged.

### G6 — Termination (recommendation)
- **Evidence:** PO8; the scan over a finite `list`.
- **Classification:** termination/performance gap (partial-correctness default).
- **UltimatePowers question:** none (trivially terminating).
- **Recommended change:** **none.** If total correctness is ever required, add
  measure `size(fb)` to `(SCAN-LOOP)`.
- **Tests:** none.

---

## Machine-check to upgrade confidence
Run the `kompile`/`kprove` commands in `fvk/PROOF.md` §5. A `#Top` from `kprove`
turns every "constructed" PO into "machine-checked" and unlocks the (currently
withheld) test-consolidation recommendations in `fvk/PROOF.md` §6.
