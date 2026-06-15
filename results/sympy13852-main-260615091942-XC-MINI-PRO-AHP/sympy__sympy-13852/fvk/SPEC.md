# SPEC.md — FVK specification for `polylog._eval_expand_func`

Target: `sympy/functions/special/zeta_functions.py`, class `polylog`, method
`_eval_expand_func` (and the docstring doctest it owns). Audit of the V1 fix for
issue **sympy/sympy#13852** ("Add evaluation for polylog").

Formal core: [`mini-python.k`](mini-python.k), [`polylog-spec.k`](polylog-spec.k).
Companion artifacts: [`FINDINGS.md`](FINDINGS.md), [`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md),
[`PROOF.md`](PROOF.md), [`ITERATION_GUIDANCE.md`](ITERATION_GUIDANCE.md).

---

## 1. INTENT_SPEC (intent-only, written before accepting candidate behavior)

Derived **only** from the public issue text, the `polylog` docstring/API, and
standard (default-domain) dilogarithm mathematics. Current code behavior is
recorded later as "observed," never as expected by itself.

- **I1 — `Li₁` expansion is exp_polar-free.** `expand_func(polylog(1, z))` must
  equal `-log(1 - z)`. Evidence: *"polylog(1, z) and -log(1-z) are exactly the
  same function for all purposes … both return the same values"*; *"having
  exp_polar in expressions like -log(1 + 3*exp_polar(-I*pi)) is just not
  meaningful."* Semantic obligation: postcondition = `-log(1-z)`; the result must
  contain **no** `exp_polar`.
- **I2 — derivative consistency.** `expand_func(diff(polylog(1,z) + log(1-z), z))`
  must be `0`. Evidence: issue shows this as the correct identity, and shows the V0
  output *breaks* it. Semantic obligation: the `s==1` expansion must be a function
  whose derivative matches `polylog(1,z).diff(z)` after expansion.
- **I3 — dilogarithm special value.** `polylog(2, Rational(1,2)).expand(func=True)`
  must equal `-log(2)**2/2 + pi**2/12`. Evidence: *"The answer should be
  -log(2)**2/2 + pi**2/12."* The value is shown **under** `.expand(func=True)`
  (In[2]), so the placement obligation is the **expand_func / transform path**,
  not necessarily auto-evaluation in `eval` (intent-evidence.md §3 "Output form /
  evaluation point": a value shown only under a transform binds under that
  transform).
- **I4 — family completeness (dilogarithm special values).** The issue title
  "Add evaluation for polylog" + the single example `Li₂(1/2)` describes a
  **family** (special values of the dilogarithm). Obligation = the whole *known
  derivable* set, not just `1/2` (intent-evidence.md §3 family/table completeness).
  Enumerated in §3 below.
- **I5 — targeted / no regression.** Orders and arguments outside the specified
  special cases must keep returning `polylog(s, z)` unchanged; the `lerchphi`
  reduction (which calls `polylog(...)._eval_expand_func`) and `hyperexpand`
  outputs must not change for symbolic `s`. Evidence: bug-fix tasks must be
  minimal; docstring contract `polylog(s, z).diff(z) == polylog(s - 1, z)/z`
  and the lerchphi reduction examples must keep holding.

**Default-domain assumptions named:** standard branch of the dilogarithm/log as
used by mpmath (the engine SymPy's `evalf` delegates to); the dilogarithm
functional equations (reflection, Landen, duplication, inversion) hold; `S.Half`
is SymPy's unique canonical object for `1/2`.

**No `eval`-auto-evaluation invariant is asserted.** Per the §42 warning in
`formalize.md` (which names *this* issue): the issue's In[1] showing
`polylog(2, 1/2)` printing unevaluated is the *symptom context*, **not** an
invariant to preserve. We neither enshrine "stays unevaluated" nor blindly invert
it; placement is decided by the positive evidence I3 (shown under a transform).

---

## 2. Public intent ledger (PUBLIC_EVIDENCE_LEDGER)

| # | Source | Quoted evidence | Semantic obligation | Status |
|---|--------|-----------------|---------------------|--------|
| L1 | prompt | "polylog(2, Rational(1,2)).expand(func=True) … The answer should be -log(2)\*\*2/2 + pi\*\*2/12" | `expand_func` postcondition for `(s,z)=(2,½)` | **encoded** — branch 3, claim (POLYLOG-DILOG-HALF) |
| L2 | prompt | "Why does the expansion of polylog(1, z) have exp_polar(-I\*pi)? … not meaningful" | `s==1` expansion = `-log(1-z)`, no exp_polar | **encoded** — branch 1, claim (POLYLOG-S1) |
| L3 | prompt | "polylog(1, z) and -log(1-z) are exactly the same function … both return the same values" | `Li₁(z) ≡ -log(1-z)` incl. branch cut | **encoded** — adequacy of (POLYLOG-S1) |
| L4 | prompt | "expand_func(diff(polylog(1, z) + log(1 - z), z))   # 0" | derivative consistency (I2) | **encoded** — follows from branch 1 + branch 2(s=0) |
| L5 | prompt (title) | "Add evaluation for polylog" + single `Li₂(½)` example | family: dilogarithm special values (I4) | **partly encoded** — `½` done; others → FINDINGS F1–F3 |
| L6 | docs | docstring `>>> expand_func(polylog(1, z))` example | doctest must match new output `-log(-z + 1)` | **encoded** — docstring updated |
| L7 | docs | docstring `polylog(s, z).diff(z) == polylog(s - 1, z)/z` | fdiff unchanged; expansion must be diff-consistent | **preserved** — fdiff untouched |
| L8 | public-test | `test_zeta_functions.py:131` asserts `-log(1 + exp_polar(-I*pi)*z)` | — | **SUSPECT** — encodes the reported bug; see FINDINGS F4 |
| L9 | public-test | `test_hyperexpand.py:582` `== -log(1 + -z)` | library canonical form is `-log(1-z)` | **supports L2** (positive evidence) |
| L10 | implementation | `eval` reduces `z∈{0,1,-1}` for all `s` | these are z-based, all-`s` reductions | **observed** — consistent with branch 1 (checked §5) |

---

## 3. Family enumeration — dilogarithm (s = 2) special values (obligation I4/L5)

The dilogarithm's standard closed-form special values, with where each is handled:

| argument z | value Li₂(z) | handled by | status |
|---|---|---|---|
| `0` | `0` | `eval` (`z==0`) | pre-existing ✓ |
| `1` | `π²/6` | `eval` (`z==1 → zeta(2)`) | pre-existing ✓ |
| `-1` | `-π²/12` | `eval` (`z==-1 → -dirichlet_eta(2)`) | pre-existing ✓ |
| `1/2` | `π²/12 − log(2)²/2` | **branch 3 (V1)** | **fixed ✓** |
| `2` | `π²/4 − iπ·log(2)` (branch-cut dependent) | — | **F1** (value not confidently derivable; on the cut) |
| `1/φ = (√5−1)/2` | `π²/10 − log(φ)²` | — | **F2** (derived; arg-recognition deferred) |
| `1/φ² = (3−√5)/2` | `π²/15 − log(φ)²` | — | **F2** |
| `−1/φ = (1−√5)/2` | `−π²/15 + log(φ)²/2` | — | **F2** |
| `−φ = −(1+√5)/2` | `−π²/10 − log(φ)²` | — | **F2** |

with `φ = (1+√5)/2`. The four golden-ratio values were **derived and
triple-checked** (reflection ⊕ Landen ⊕ duplication all mutually consistent) — see
[`PROOF.md`](PROOF.md) §A2 and [`FINDINGS.md`](FINDINGS.md) F2; they are *derived,
not guessed*, but deferred for a positive-grounds reason (argument canonicalization
risk), not on bare "scope."

**Why `1/2` is in the safe set and the others are not.** `S.Half` is SymPy's
unique canonical representation of `1/2`, so `z == S.Half` is guaranteed to match
(no dead code, no false match). The golden-ratio arguments have **no canonical
SymPy form** (`(sqrt(5)-1)/2`, `1/GoldenRatio`, … are distinct objects), so a
`z == (sqrt(5)-1)/2` guard could silently never fire (dead code) — un-confirmable
without execution. `Li₂(2)`'s *argument* is clean but its *value*'s imaginary-part
sign is branch-cut dependent and not confidently derivable. Hence: add `1/2`;
record `2` and golden-ratio as Findings with the derivations preserved.

Broader families (trilogarithm `Li₃(1/2) = 7ζ(3)/8 − π²log2/12 + log³2/6`, general
`Li_n(1/2)`) are **out of the dilogarithm family** the example exhibits and carry
coefficient uncertainty → [`FINDINGS.md`](FINDINGS.md) F3.

---

## 4. Specification of each branch of `_eval_expand_func`

The method is a non-recursive **dispatch** with four reachable branches plus an
internal counting loop. Within-unit completeness (every branch, every in-domain
input class):

- **Branch 1 — `s == 1`** (CHANGED). Precondition: `s = 1` (any `z` not caught by
  `eval`). Postcondition: returns `-log(1 - z)`, exp_polar-free.
  Claim `(POLYLOG-S1)`. Obligations I1, I2, L2, L3, L4.
- **Branch 2 — `s` integer `≤ 0`** (UNCHANGED). Precondition: `s ∈ ℤ, s ≤ 0`.
  Postcondition: `expand_mul((u·d/du)^(−s)[u/(1−u)]).subs(u,z)`, a rational
  function. Loop circularity `(LOOP)`. The differentiation's *mathematical*
  correctness is inherited from `test_polylog_expansion` (trusted base).
- **Branch 3 — `s == 2 and z == S.Half`** (ADDED). Precondition: `s = 2 ∧ z = ½`.
  Postcondition: `-log(2)**2/2 + pi**2/12`. Claim `(POLYLOG-DILOG-HALF)`.
  Obligations I3, L1.
- **Branch 4 — otherwise** (UNCHANGED). Precondition: none of 1–3 (e.g. `s ≥ 3`,
  or `s = 2 ∧ z ≠ ½`, or non-integer `s`). Postcondition: `polylog(s, z)`
  unchanged. Claims `(POLYLOG-DEFAULT)`, `(POLYLOG-DILOG-NONHALF)`. Obligation I5.

Domain note (fixed from intent, not the diff): the contract ranges over **all**
`(s, z)` reaching `_eval_expand_func`, i.e. all `polylog` instances not already
reduced by `eval`. The fix's branches are a slice of that domain; branches 2 and 4
are specified too so the audit can see the new branch 3 does not disturb them.

---

## 5. Consistency check: `eval` (z∈{0,1,-1}) vs. branch 1 `-log(1-z)`

`eval` intercepts `z∈{0,1,-1}` for every `s`, so those never reach branch 1.
Cross-checking they agree anyway (no contradiction at the seam):

- `polylog(1,0)`: `eval → 0`; `-log(1-0) = -log 1 = 0`. ✓
- `polylog(1,1)`: `eval → zeta(1) = zoo`; `-log(1-1) = -log 0 = zoo`. ✓
- `polylog(1,-1)`: `eval → -dirichlet_eta(1) = -log 2`; `-log(1-(-1)) = -log 2`. ✓

The branch-1 closed form is the analytic continuation of the `eval` boundary
values; the fix introduces no discontinuity.

---

## 6. SPEC_AUDIT summary (full table in PROOF.md §C)

Round-trip: INTENT_SPEC (§1) → K claims (`polylog-spec.k`) → English paraphrase
(PROOF.md §B) → comparison.

- I1 → (POLYLOG-S1): **pass.** I2 → branch1+branch2(s=0): **pass.**
- I3 → (POLYLOG-DILOG-HALF), expand_func placement: **pass.**
- I4 (family) → `1/2` **pass**; `2`, golden-ratio, `Li_n` → **deferred** (F1–F3),
  values derived, recorded; not marked "proven."
- I5 → (POLYLOG-DEFAULT), (POLYLOG-DILOG-NONHALF): **pass.**

No SPEC_AUDIT entry is `fail`. The only `ambiguous→deferred` items are the
non-`1/2` family members, which do **not** justify `V2 == V1` by themselves — they
are open Findings, and V1 is accepted on the *positive* grounds that the
demonstrated, cleanly-implementable intent (I1–I3, I5) is fully met (§7).

---

## 7. Verdict input

V1 satisfies I1, I2, I3, I5 and the cleanly-derivable part of I4 (`Li₂(1/2)`).
The deferred family members (F1–F3) are recorded with derivations and a concrete
recommended implementation, rejected for V1 on positive feasibility/correctness
grounds (argument canonicalization / branch-cut value uncertainty), **not** on
scope alone. See [`PROOF.md`](PROOF.md) for the constructed proof and the
public-compatibility audit, and [`reports/fvk_notes.md`](../reports/fvk_notes.md)
for the per-decision trace.
