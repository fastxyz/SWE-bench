# ITERATION_GUIDANCE.md — feedback for the next code/spec pass

Accumulated guidance from `/formalize` + `/verify` on the `nthroot_mod` fix
(sympy__sympy-18199). Each item: classification · evidence · UltimatePowers question ·
recommended next change · tests.

---

## G1 — Confirm V1 (no code change this iteration)

- **Classification:** verified — keep.
- **Evidence:** `CLAIM-ZERO` discharged; PO-ROOT, PO-ONLY, PO-EQUIV, PO-COMPLETE, PO-SHAPE
  proved; PO-PRIME, PO-NGE1 enforced by upstream guards (FINDINGS F2). The branch is the
  minimal correct short-circuit and is robust across every `a%p==0` sub-case that previously
  returned-by-luck or crashed (FINDINGS F1).
- **UltimatePowers question:** none — intent (issue L1–L3) is fully met.
- **Recommended change:** none. V1 stands exactly as at `residue_ntheory.py:779–781`.
- **Tests:** add the two pins below (G5).

## G2 — `n == 1` returns an unreduced representative (pre-existing, separate issue)

- **Classification:** latent code bug, **out of scope** for #18199.
- **Evidence:** FINDINGS F4 — `nthroot_mod(20,1,7)` → `20` instead of canonical `6`. Triggered
  only on `a%p != 0`, the complement of this fix; the fix's `n==1, a%p==0` sub-case is correct.
- **UltimatePowers question:** "Should `nthroot_mod` always return roots reduced to `[0, p)`?
  (Every branch except the `n==1`/`_nthroot_mod2` path already does.)"
- **Recommended change (future PR, not now):** reduce in `_nthroot_mod1`/`_nthroot_mod2`, or
  add `a %= p` at the top of `nthroot_mod` after the `n==2` delegation. Out of scope here to
  keep the change minimal and avoid touching the `a%p≠0` algorithm.
- **Tests:** if taken up, add `nthroot_mod(20,1,7) == 6`.

## G3 — `n == 0` raises `ZeroDivisionError` (pre-existing, out of domain)

- **Classification:** out-of-domain input handling, **out of scope** for #18199.
- **Evidence:** FINDINGS F5 — `nthroot_mod(1,0,7)` → `ZeroDivisionError` at `(p-1) % n`.
  Docstring says "n : positive integer", so `n=0` is undocumented; the fix never reaches it
  for `a%p==0` (short-circuited to `None` by `is_nthpow_residue`).
- **UltimatePowers question:** "For `n = 0` should the function raise `ValueError('n must be
  positive')`, or is `n ≥ 1` a hard documented precondition callers must honor?"
- **Recommended change (future):** an explicit `n >= 1` guard with a clear error. Not now.
- **Tests:** if taken up, `raises(ValueError, lambda: nthroot_mod(1, 0, 7))`.

## G4 — Pre-existing solver correctness is *assumed*, not proved (escalation)

- **Classification:** proof capability gap / `[ESCALATION BOUNDARY]` — not a bug.
- **Evidence:** PO-SOLVE / ASSUME-SOLVE — `_nthroot_mod1` (discrete-log based) and the
  gcd-on-exponents loop are assumed correct on `a%p≠0`. Full proof needs primitive-root and
  `(Z/pZ)*` theory beyond the bundled tier.
- **UltimatePowers question:** "Is mechanizing the `_nthroot_mod1` discrete-log algorithm in
  scope, or do we rely on the existing exhaustive randomized tests for it?"
- **Recommended change:** none to code; keep `test_residue.py:176–187` as the guardrail for
  that path (do **not** flag it redundant — PROOF.md test-redundancy §).

## G5 — Recommended test additions (pin the fixed behavior)

- **Classification:** test gap (the fixed slice has no existing pin; F PF4).
- **Recommended additions** (in the project's normal test location, by the maintainers — this
  task does not modify tests):
  - `assert nthroot_mod(17*17, 5, 17) == 0` — the issue's example (gcd path, `gcd(5,16)=1`).
  - `assert nthroot_mod(17*17, 5, 17, True) == [0]`.
  - `assert nthroot_mod(11, 5, 11) == 0` — exercises the `(p-1)%n==0` → `_nthroot_mod1` path
    that **crashed** pre-fix (regression guard for the strongest failure mode, F1).
  - `assert nthroot_mod(13, 9, 13, True) == [0]` — gcd path with `gcd(9,12)=3>2`, the other
    pre-fix crash mode.
  - optional: extend the exhaustive loop lower bound to include `a ≡ 0`, i.e. check
    `nthroot_mod(0, q, p, True) == [0]` for the looped `(q,p)`.
- **Keep:** all current tests (each lies outside `CLAIM-ZERO`'s domain — PROOF.md §test).

---

## One-line disposition

V1 is **confirmed correct and minimal**; the only follow-ups (G2, G3) are pre-existing,
clearly-scoped, and intentionally deferred; the only open proof items (G4, and the machine
recheck of Euclid's lemma) are escalation/assumed, not defects in the fix.
