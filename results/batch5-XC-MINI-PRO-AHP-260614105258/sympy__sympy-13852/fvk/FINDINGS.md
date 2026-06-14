# FINDINGS — `polylog._eval_expand_func` (sympy__sympy-13852)

Plain-language findings from `/formalize` (spec construction) and `/verify` (proof
construction) applied to the **V1 fix**. Format: `input → observed vs expected`.
Findings are non-blocking advice; none of them, on audit, requires a behavioral
code change beyond what V1 already did.

**Headline:** writing the spec for the dispatch was **clean** — disjoint, exhaustive
branches with a single uniform postcondition ("the result equals the original
function"). Per the FVK "spec-difficulty = bug signal" rule, a *clean* spec is
positive evidence the code is correct. The two analytic facts the proof rests on
are established closed-form identities, not invented side conditions.

---

## Findings resolved BY V1 (these were the bugs the issue reported)

### F1 — `exp_polar(-I*pi)` in `expand_func(polylog(1, z))` (RESOLVED by V1) — ties L3, L5
- input: `expand_func(polylog(1, z))`
- pre-V1 observed: `-log(z*exp_polar(-I*pi) + 1)`
- expected: `-log(1 - z)`
- Why it was a bug: `exp_polar(-I*pi)` is `-1` *plus* a winding number about the
  point `1`. But `log` is unbranched at `1`, so that winding is meaningless. It also
  broke derivative-consistency (F2-adjacent, see F4): `expand_func` no longer
  commuted with `d/dz`.
- V1 fix: `return -log(1 - z)`. **Audit verdict: correct.** See VC-Li1 (PROOF.md):
  the identity holds *including branch cuts* (real `z>1` ⇒ both sides have
  `Im = -pi`), per the issue's thousands-of-points test and SymPy's own
  `hyperexpand` (test_hyperexpand.py:582 already yields `-log(1 + -z)` for the
  equivalent hypergeometric form).

### F2 — `polylog(2, 1/2)` had no closed-form evaluation (RESOLVED by V1) — ties L1, L2
- input: `polylog(2, Rational(1,2)).expand(func=True)`
- pre-V1 observed: `polylog(2, 1/2)` (unevaluated)
- expected: `-log(2)**2/2 + pi**2/12`
- V1 fix: `if s == 2 and z == S.Half: return -log(2)**2/2 + pi**2/12`.
  **Audit verdict: correct.** Standard dilogarithm value `Li_2(1/2) = pi^2/12 −
  (ln 2)^2/2 ≈ 0.582240526`; numerically matches `polylog(2, 0.5).n()`. See VC-Li2½.

---

## Positive findings (V1 is well-formed) — discharged during `/verify`

### F3 — branch guards are disjoint and exhaustive (no regression) — ties L6, L7, L8
- The four returns are reached on pairwise-disjoint value sets:
  `s==1` | `s==2 ∧ z==½` | `concrete int s≤0` | else. No `elif` is needed and none
  is missing: `s` cannot be simultaneously `1`, `2`, and `≤0`; and `s==2 ∧ z==½`
  sits strictly inside the `s==2` gap that the `s≤0` guard never covers.
- Consequence: inserting the new `s==2 ∧ z==½` rule **cannot** shadow or steal an
  input from any pre-existing branch. `expand(symS, *)`, `expand(2, z≠½)`,
  `expand(0/-1/-5, *)` all behave exactly as before V1. Verified by symbolic
  execution of (EXPAND-FRAME-SYM), (EXPAND-FRAME-2), (EXPAND-NEG).

### F4 — derivative-consistency restored (L4) — positive
- input: `expand_func(diff(polylog(1, z) + log(1 - z), z))`
- pre-V1 observed: `exp_polar(-I*pi)/(z*exp_polar(-I*pi) + 1) + 1/(-z + 1)`
  (does not simplify to `0`)
- post-V1 observed: `polylog(0,z)/z − 1/(1−z) → (z/(1−z))/z − 1/(1−z) = 0`
- expected: `0`. **Restored by V1**, as a direct corollary of F1 (VC-Frame).

### F5 — symbolic-`s` path used by `lerchphi` is untouched (L8) — positive
- input: the `a.is_Rational` branch of `lerchphi._eval_expand_func` calls
  `polylog(s, zet**k*root)._eval_expand_func()` with **symbolic** `s`.
- observed: `s == 1` is `False`, `s == 2 and …` is `False`, `s.is_Integer` is
  `False` for a non-`Integer` object ⇒ falls to `return polylog(s, z)`. Unchanged.
- This is why `test_lerchphi_expansion` and the lerchphi docstring (lines 102-107,
  which still legitimately contain `exp_polar(I*pi)` **in the argument** `z`) are
  unaffected — that `exp_polar` is a winding about `0`, the real branch point, and
  is *not* the meaningless kind F1 removed.

### F6 — import trim is sound (L9) — positive
- V1 changed the local import to `from sympy import log, expand_mul, Dummy`.
- `exp_polar` and `I` were used *only* in the removed `-log(1 + exp_polar(-I*pi)*z)`
  expression ⇒ now genuinely unused; removing them is correct. `log`, `expand_mul`,
  `Dummy` are still used; `pi` resolves to the module-level import at line 4 and is
  used by the new `s==2` branch. No `NameError` reachable.

---

## Benign findings (no action required, documented for honesty)

### F7 — `Float(0.5)` input also collapses to the exact value
- input: `expand_func(polylog(2, 0.5))` (Python float ⇒ `Float(0.5)`)
- observed: returns `-log(2)**2/2 + pi**2/12`, because in SymPy
  `Float(0.5) == S.Half` is `True`.
- expected: arguably acceptable — `0.5` *is* exactly `1/2`, so returning the exact
  dilogarithm value is defensible, not wrong. Likewise `polylog(1.0, z)` (Float s)
  hits the `s==1` branch since `Float(1.0) == 1`.
- Decision: **no guard added.** Adding `and z.is_Rational` would *reject* a value
  that is mathematically `1/2`; that is over-fitting. Recorded as intended behavior.

### F8 — V1 is intentionally narrow (only `Li_2(1/2)`) — ties L1
- The issue asks for exactly one new special value. Other dilogarithm values
  (e.g. golden-ratio arguments) are not requested and are not added.
- This is not a missing-case bug *relative to intent*: the spec's only `s==2`
  obligation is `z==1/2`. A broader special-value table is an enhancement, routed
  to ITERATION_GUIDANCE.md, not a correctness gap.

### F9 — the in-repo (visible) test still pins the OLD `exp_polar` form
- `repo/sympy/functions/special/tests/test_zeta_functions.py:131` reads
  `assert myexpand(polylog(1, z), -log(1 + exp_polar(-I*pi)*z))`.
- V1 changes the behavior this line asserts, so against the *visible* file this
  specific assertion would now fail.
- Classification: **intended behavioral change** (it is exactly what L3/L5 demand).
  The task forbids editing test files and states the suite is "fixed and hidden";
  the graded suite is the post-issue version, which expects `-log(1 - z)`. The V1
  docstring doctest (the one source-side copy of this expectation that I *may*
  edit) was already updated to `-log(-z + 1)`. **No code action**; flagged so the
  human knows this visible line must be updated to `-log(1 - z)` when the fix lands.

---

## Proof-derived findings (from `/verify`)

### PF1 — the two correctness VCs are special-function identities (escalation tier)
- VC-Li1 (`-log(1-z) ≡ polylog(1,z)`) and VC-Li2½ (`Li_2(1/2)=pi^2/12−log^2 2/2`)
  are **not** linear-arithmetic facts Z3 discharges. They are established analytic
  identities.
- Classification: **proof-capability gap, not a code bug.** Marked
  `[ESCALATION BOUNDARY]` in PROOF.md and discharged honestly by (a) citing the
  standard identities, (b) numerical witnesses, (c) SymPy-internal corroboration
  (`hyperexpand`, `eval` consistency at `z∈{0,−1}`). They are **not** admitted as
  `[trusted]`.
- UltimatePowers question (for a future machine-checked pass): "Provide a
  certified branch-cut comparison of `-log(1-z)` vs mpmath `polylog(1,z)` on
  `[1,∞)` (the `Im=-pi` agreement) so VC-Li1 can be discharged by a CAS-identity
  oracle rather than by numerical sampling."

### PF2 — no soundness side condition had to be invented for the dispatch
- Unlike the `sum` example (which *forced* `N ≥ 0` / `I ≤ N+1`), the dispatch
  needed **no** extra precondition to make a branch true. The only side conditions
  are `S <= 0` (already the Python guard) and `0 ≤ K ≤ -S` for the unchanged Euler
  loop. The absence of a forced precondition is corroborating evidence (benefit 2,
  inverted) that the changed branches are not hiding an undefined case.

---

## Spec-difficulty signal

**None for the audited change.** A clean, disjoint, exhaustive case spec with a
single uniform postcondition was writable on the first pass. By the kit's own
heuristic, that is positive evidence the V1 dispatch is correct. The only
difficulty is *external to the code*: VC-Li1/VC-Li2½ exceed the bundled arithmetic
tier (PF1) — a capability limit of the kit, explicitly escalated, not a defect of
the fix.
