# FVK notes — django__django-16631

How the Formal Verification Kit audit was applied to the V1 fix, and the
justification for every decision. **Outcome: V1 stands unchanged — no source
edit.** Each decision below is traced to specific entries in
`fvk/FINDINGS.md` (Fn) and `fvk/PROOF_OBLIGATIONS.md` (POn).

## What V1 is (recap)
1. `django/contrib/auth/base_user.py` — added `from django.conf import
   settings`; split `get_session_auth_hash()` into a private
   `_get_session_auth_hash(secret=None)` and added the generator
   `get_session_auth_fallback_hash()` (one hash per `SECRET_KEY_FALLBACKS`
   entry).
2. `django/contrib/auth/__init__.py` `get_user()` — on a current-key mismatch,
   also checks the fallback hashes; on a fallback match it **upgrades**
   (`cycle_key()` + rewrite `_auth_user_hash` to the current-key hash); otherwise
   flushes as before.

## Method applied
Ran the FVK loop conceptually (no execution environment, per the task): built a
mini-X K semantics (`fvk/mini_auth.k`) of just the fragment the fix touches,
wrote three reachability claims (`fvk/mini_auth-spec.k`) — `(HASH-EQ)`,
`(SCAN-LOOP)`, `(GETUSER)` — `/formalize`d the intent/code/spec alignment into
`fvk/FINDINGS.md`, and `/verify`-constructed the proof in `fvk/PROOF.md`
(discharging PO1–PO10). All artifacts are labeled **constructed, not
machine-checked**; the `kompile`/`kprove` commands are recorded in `PROOF.md` §5.

## Why no code change was made

The decisive test (per FVK): could a *clean* spec be written? Yes — `(GETUSER)`
is three mutually-exclusive, exhaustive cases (`KEEP`/`UPGRADE`/`FLUSH`) with a
clean membership predicate, no invented side condition, no non-universal
postcondition (**F8**). Spec-difficulty would have been a bug signal; its absence
is positive evidence. Concretely:

- **Core bug fixed.** The reported logout-on-rotation is `F0`; V1 turns that
  exact input from `FLUSH` into `UPGRADE` — discharged as **PO2** (user kept iff
  `H ≠ eps ∧ H ∈ {HC} ∪ FB`).
- **Backward compatibility — the keystone.** The refactor must not change any
  existing digest, or it would re-create the mass logout. **F1 / PO1**
  (`HASH-EQ`) shows both the V1 path (`secret=None`) and the pre-fix path
  (`secret` omitted) reduce to the identical `H3(SALT,PWD,SK)` via
  `salted_hmac`'s `if secret is None` default. Confirmed; no change needed.
- **Degenerate inputs reduce to pre-fix behavior.** `SECRET_KEY_FALLBACKS = []`
  and empty `session_hash` both collapse to the original flush — **F3 / PO5,
  PO6**. The empty-hash path also proves the generator is never called (Python
  `and` short-circuit), so there is nothing to harden.
- **Upgrade convergence (the public hint).** The hint warned that mere
  acceptance would re-invalidate sessions when fallbacks are removed. V1's
  `cycle_key()` + hash rewrite makes rotation converge in one request — **F5 /
  PO9**. This mirrors the hint's own suggestion to "call
  `update_session_auth_hash()` when a fallback hash is valid" (that helper *is*
  `cycle_key()` + hash rewrite), so `cycle_key()` is kept deliberately, not by
  accident.
- **Definedness.** The one genuinely subtle correctness point — could
  `session_auth_hash` be read while unbound? — is **F2 / PO4**: the read at
  `__init__.py:218` is dominated by `if session_hash and any(...)`, which
  short-circuits on the same falsy `session_hash` that skips the assignment. No
  `UnboundLocalError`. The proof flags that the **conjunct order is
  load-bearing** (G2), so this is recorded as an invariant to preserve, not a
  bug to fix.

Because PO1–PO10 all discharge (PO8 trivially, as a recommendation) and no proof
obstacle or `[ESCALATION BOUNDARY]` arose, the audit *confirms* V1 rather than
revising it.

## Issues the audit surfaced and why each was NOT a code change

- **F4 — duck-typed user lacking `get_session_auth_fallback_hash`** would raise
  `AttributeError` on the fallback path. **Decided: accept, do not guard.**
  Rationale traced in F4 and ITERATION_GUIDANCE **G3**: the method ships on
  `AbstractBaseUser` (Django's required base; a repo grep finds
  `get_session_auth_hash` defined *only* there), and the pre-existing code at
  `__init__.py:205` already calls `get_session_auth_hash()` directly once
  `hasattr` is true — so V1 stays consistent with the established all-or-nothing
  protocol. Adding `hasattr(user, "get_session_auth_fallback_hash")` would only
  change behavior for an unsupported object and diverge from the minimal
  paired-method design. Recorded as an UltimatePowers question instead.
- **F6 — non-constant-time fallback iteration.** Accept: the fallback *count* is
  config, not a secret, and per-candidate comparison stays
  `constant_time_compare`; identical to `PasswordResetTokenGenerator.check_token`
  (`tokens.py:69-74`). Intent I5 met. (G4.)
- **F7 — `login()` not made fallback-aware.** Deliberate scope: that is the
  active re-authentication / session-fixation path, not the passive validation
  path the ticket reports; it rewrites the hash to the current key anyway, and
  changing its session-reuse guard carries security risk for zero benefit to the
  reported bug. (G5.)

## Residual risk (carried, not resolved by code)
1. *Constructed, not machine-checked* — `PROOF.md` §5 gives the commands to
   close this.
2. *Partial correctness* — termination (PO8) is a trivial recommendation
   (finite `SECRET_KEY_FALLBACKS`).
3. *Trusted base* — HMAC/`constant_time_compare` modeled abstractly (we verified
   the fix's control/data flow, not cryptography or the timing channel, F6);
   `inList`'s defining equations are spec vocabulary; mini-X adequacy + the
   reachability metatheory + the SMT oracle are trusted. Nothing faked
   `[trusted]`.

## Net
The FVK audit confirms V1 is correct and complete for the reported issue and its
hinted enhancement. No source files were changed in this pass; the evidence
package (`fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`,
`fvk/PROOF.md`, `fvk/ITERATION_GUIDANCE.md`, plus the two `.k` files) justifies
leaving V1 as the final fix.
