# FINDINGS.md — `polylog._eval_expand_func` (issue #13852)

Plain-language findings, each `input → observed vs expected`. Findings are
**non-blocking**. F-CONFIRM items record what V1 already gets right (with the
adversarial reproduction that localizes the bug); F1–F5 are open items.

---

## Confirmations (V1 is correct here) — with adversarial reproduction

**F-CONFIRM-1 — Li₁ exp_polar removal (issue Part 2).**
`expand_func(polylog(1, z))` → V0 observed `-log(z*exp_polar(-I*pi) + 1)`;
expected `-log(1 - z)` (= `-log(-z + 1)`). V1 returns the expected value.
*Adversarial reproduction:* on V0 the branch-1 rule `return -log(1 + exp_polar(-I*pi)*z)`
literally injects `exp_polar`; replacing it with `-log(1 - z)` removes the symbol
at its source. The mechanism in the spec (`mini-python.k` branch 1) is exactly the
line the issue points at — *pointed-at-the-spot* satisfied.

**F-CONFIRM-2 — derivative consistency (issue Part 2).**
`expand_func(diff(polylog(1,z) + log(1-z), z))` → V0 observed a non-zero
`exp_polar(-I*pi)/(z*exp_polar(-I*pi)+1) + 1/(-z+1)`; expected `0`. With V1,
`diff(polylog(1,z)) = polylog(0,z)/z`, and branch 2 (`s=0`) gives `z/(1-z)`, so the
expression collapses to `1/(1-z) − 1/(1-z) = 0`. Fixed.

**F-CONFIRM-3 — dilogarithm value Li₂(1/2) (issue Part 1).**
`polylog(2, Rational(1,2)).expand(func=True)` → V0 observed `polylog(2, 1/2)`
(unevaluated); expected `-log(2)**2/2 + pi**2/12`. V1 branch 3 returns it.
Value re-derived from the reflection law (PROOF.md §A2); numeric check ≈ 0.5822.

**F-CONFIRM-4 — placement is correct (expand_func, not eval).**
The value is shown under `.expand(func=True)` (In[2]), so it binds on the
transform path — V1 places it in `_eval_expand_func`. We did **not** enshrine
"stays unevaluated in eval" as an invariant (formalize.md §42), and we did **not**
blindly move it to `eval` either; the positive evidence (transform form) decides
placement. Auto-evaluating in `eval` would also be inconsistent with the other
`s`-specific reductions (`s==1`, `s≤0`) which all live in `_eval_expand_func`,
whereas `eval` holds only z-based, all-`s` reductions (`z∈{0,1,-1}`).

**F-CONFIRM-5 — targeted, no regression.** `lerchphi._eval_expand_func` calls
`polylog(s, …)._eval_expand_func` only with **symbolic** `s` in all tested cases,
so branches 1/3 never fire there; `hyperexpand` produces `-log(1-z)` itself
(`test_hyperexpand.py:582`) and uses `polylog(2,z)`/`polylog(3,z)` symbolically
(`:583-584`, `:608`) — all untouched by V1.

---

## Open findings

**F1 — `Li₂(2)` special value not handled.**
input `polylog(2, 2).expand(func=True)` → observed `polylog(2, 2)`; the standard
value is `π²/4 − iπ·log(2)`. **Classification:** missing family member, *value not
confidently derivable*. The argument `z=2` IS clean (would match), but `z=2` lies
**on** the branch cut `[1,∞)`, so the imaginary part's sign depends on the
approach direction / branch convention (the very subtlety issue Part 2 cares
about). Guessing the sign would risk a value that disagrees with mpmath's
`evalf`. **Recommendation:** add only after confirming the sign against
`mpmath.polylog(2, 2)`; until then keep as a Finding, not code. **Never guess a
value you cannot derive** (intent-evidence.md §3).

**F2 — golden-ratio dilogarithm values not handled (derived, deferred).**
inputs `polylog(2, (sqrt(5)-1)/2)`, `polylog(2, (3-sqrt(5))/2)`,
`polylog(2, (1-sqrt(5))/2)`, `polylog(2, -(1+sqrt(5))/2)` → observed unevaluated.
**Derived values** (φ = (1+√5)/2), *triple-checked* in PROOF.md §A3 by reflection
⊕ Landen ⊕ duplication, all mutually consistent:
- `Li₂(1/φ) = π²/10 − log(φ)²`
- `Li₂(1/φ²) = π²/15 − log(φ)²`
- `Li₂(−1/φ) = −π²/15 + log(φ)²/2`
- `Li₂(−φ) = −π²/10 − log(φ)²`

**Classification:** derivable family members, **implementation deferred on positive
feasibility grounds** (not bare scope). Reason: unlike `S.Half`, these arguments
have **no canonical SymPy representation** — `(sqrt(5)-1)/2`, `1/S.GoldenRatio`,
`S.GoldenRatio - 1` are distinct objects. A `z == (sqrt(5)-1)/2` guard would match
only one spelling and could silently be **dead code** for the others, which cannot
be confirmed without execution. A robust fix needs an argument-canonicalization
step (e.g. normalize via `S.GoldenRatio`, or `nsimplify`-style recognition) that
the issue neither specifies nor demonstrates, and that introduces its own
correctness surface. **Recommendation (next iteration):** implement golden-ratio
recognition with explicit canonicalization + a test matrix over representations;
the four values above are ready to drop in. *(Promoted to a tested hypothesis per
verify.md Step 3 and rejected on feasibility/correctness, not "out of scope.")*

**F3 — higher polylogarithm `Li_n(1/2)` values not handled.**
input `polylog(3, Rational(1,2)).expand(func=True)` → observed `polylog(3, 1/2)`;
known `Li₃(1/2) = 7ζ(3)/8 − π²log(2)/12 + log³(2)/6`. **Classification:** outside
the **dilogarithm** family the issue example exhibits (different function), plus
the coefficients carry memory-uncertainty (7/8, 1/12, 1/6) → not confidently
derivable here. **Recommendation:** out of this issue's family; record for a future
"polylog special values" pass. No code change.

**F4 — SUSPECT legacy test encodes the reported bug.**
`test_zeta_functions.py:131`: `myexpand(polylog(1, z), -log(1 + exp_polar(-I*pi)*z))`
asserts exactly the V0 output that issue Part 2 calls *not meaningful*. Per the
SUSPECT rule (intent-evidence.md §1), this test encodes the bug and the correct
fix legitimately changes it to `-log(1 - z)`. **We do not (and may not) edit
tests**; the hidden/updated suite is expected to assert the corrected form. This
SUSPECT test is **not** a reason to keep V1's old behavior — its existence is a
positive bug signal, consistent with the fix.

**F5 — `eval` does not auto-evaluate `Li₂(1/2)` (intentional, recorded).**
input `polylog(2, Rational(1,2))` (bare) → observed `polylog(2, 1/2)` (unchanged
by V1). **Classification:** *intentional placement*, not a defect — the value is
shown only under `.expand(func=True)` (I3), so the obligation is on the transform
path. Recorded explicitly so the choice is auditable rather than silent. If a
future intent clarification (UltimatePowers Q below) wants bare auto-evaluation,
move the value into `eval`; current public evidence does not require it.

---

## Spec-difficulty signals (benefit-2 heuristic)

- Writing the spec was **clean** for branches 1, 3, 4 (clear postconditions from
  the issue), which is a positive sign the fix is well-targeted.
- The **only** difficulty was the family domain (F1–F3): the closed form exists
  but the *argument recognition* (golden ratio) or *branch* (Li₂(2)) is the hard
  part — correctly flagged as the locus of any remaining incompleteness, not
  papered over.
- No awkward implementation-derived side condition was needed; no clean-spec
  obstacle indicating a hidden bug in V1's branches.

---

## UltimatePowers questions for the next intent pass

1. Should `Li₂(1/2)` (and future special values) **auto-evaluate** in `eval`
   (changing bare `polylog(2, 1/2)`), or only under `expand_func`? (Issue shows
   only the transform form; default-domain convention says s-specific reductions
   stay in `expand_func`.)
2. Should the dilogarithm `Li₂(2)` use mpmath's branch (imaginary part
   `−π·log 2`) or stay symbolic? (Branch-cut policy.)
3. Is golden-ratio argument recognition in-scope for SymPy's `polylog`, and if so
   what canonical form (via `S.GoldenRatio`?) should drive the match?

---

## Test guidance (recommendation-only; conditioned on machine-checking)

- **Keep & expect updated:** `test_zeta_functions.py:131` (SUSPECT, F4) — should
  now assert `-log(1 - z)`; do not delete, do not edit (tests are fixed/hidden).
- **Add (next iteration):** assertions for `expand_func(polylog(2, S.Half)) ==
  -log(2)**2/2 + pi**2/12` and `expand_func(polylog(1, z)) == -log(1 - z)`.
- **Keep:** `test_hyperexpand` polylog/lerchphi cases (symbolic `s`) — out of the
  changed branches; integration coverage.
- No test is made redundant by V1 in a way that warrants removal.
