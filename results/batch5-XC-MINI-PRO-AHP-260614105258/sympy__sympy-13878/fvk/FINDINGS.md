# FINDINGS.md — audit of the V1 precomputed-CDF fix

Format: `input → observed vs expected`, plain language. Severity tags: **BUG** (wrong value
on a valid input), **FRAGILE** (right value but via a brittle evaluation path), **CONFIRM**
(spec obligation checked and met), **PRE-EXISTING** (issue not introduced by this fix),
**METHOD** (affects how the fix must be tested, not the code's correctness).

The single act that produced the bug finding F1 was writing obligation **L8** of the spec
(a CDF must equal 0 below its support) and then *evaluating each `_cdf` at its support
boundary* — exactly the "writing a clean spec flushes out the corner case" mechanism.

---

## F1 — Frechet returns `nan` at the lower support boundary  **[BUG — FIXED in V2]**

- **input:** `cdf(Frechet("x", S(4)/3, 1, 2))(2)` (evaluate at `x = m = 2`).
- **observed (V1, branch guard `x >= m`):** the `x>=m` branch is taken and computes
  `exp(-((2-2)/1)**(-4/3)) = exp(-(0**(-4/3))) = exp(-zoo) = exp(zoo) = nan`.
- **expected (L8):** `F(m) = P(X ≤ m) = 0` (the support is the *open* ray `(m, ∞)`; `m` itself
  carries zero probability).
- **root cause:** `0**(-a)` with `a>0` is `zoo` (ComplexInfinity); feeding `zoo` through `exp`
  yields `nan` because `exp` has no directional limit at complex infinity.
- **fix:** change the guard from `x >= m` to `x > m`, so `x = m` falls through to the
  `(S.Zero, True)` branch and returns `0`. Verified invisible to every interior-point test
  (for `x>m` the same branch and value are produced) and to the issue's own example
  `…(3) → exp(-1)` (unchanged). Trace: SPEC (FRECHET) boundary clause, PO-B-FRECHET.

## F2 — Dagum at `x = 0` is correct but relies on `zoo` arithmetic  **[FRAGILE — kept]**

- **input:** `cdf(Dagum("x", S(1)/3, S(1)/5, 2))(0)`.
- **observed (guard `x >= 0`):** `(1 + (0/2)**(-1/5))**(-1/3) = (1 + zoo)**(-1/3)
  = zoo**(-1/3) = 0`.
- **expected (L8):** `0`. **So the value is correct.** Unlike Frechet, the *outer* operation
  here is a **negative power** of `zoo`, and `zoo**(negative) = 0` in SymPy, which lands on the
  right answer; Frechet's outer `exp` does not.
- **decision:** the value is correct, so this is **not** changed (keeping V1 minimizes churn
  and divergence). Recorded as FRAGILE because the correctness depends on a `zoo`-evaluation
  rule rather than a clean branch. A future hardening would mirror F1 (`x > 0`); it is not
  required for correctness. Trace: SPEC (DAGUM), PO-B-DAGUM.

## F3 — All other support boundaries are clean  **[CONFIRM]**

- `Gamma/Erlang`, `GammaInverse`, `Nakagami` use guard `x > 0` and the else-branch `S.Zero`,
  so `F(0)=0` with no indeterminate form (`lowergamma`/`uppergamma`/`b/x` are never evaluated
  at the singular point). `Arcsin`, `Kumaraswamy`, `UniformSum` evaluate cleanly at **both**
  endpoints: e.g. `Kumaraswamy` `F(0)=1-(1-0**a)**b=0` and `F(1)=1-(1-1)**b=1-0**b=1` (here
  `0**(positive)=0`, not `zoo`). `Laplace`, `Logistic`, `StudentT` are total on `ℝ` (no
  boundary). Trace: SPEC §4 per-distribution boundary clauses, PO-B-*.

## F4 — Central postcondition `F'(x) = pdf(x)` holds for all 12  **[CONFIRM]**

- For every distribution, symbolic differentiation of `F` reduces to the coded `pdf` on the
  open support (Arcsin, Dagum, Gamma/Erlang, Frechet, GammaInverse, Kumaraswamy, Laplace,
  Nakagami via elementary + `(D-lower)`/`(D-upper)` rules; StudentT numerically via the
  hypergeometric identity, cross-checked against the `nu=1` Cauchy reduction
  `1/2 + atan(x)/pi`; UniformSum term-by-term, §5). Full derivations in PROOF.md PO-D-*.
- **example:** `cdf(GammaInverse("x", a, b))(x).diff(x)`
  `= -exp(-b/x)*(b/x)**(a-1)*(-b/x**2)/gamma(a) = b**a*x**(-a-1)*exp(-b/x)/gamma(a)`
  `= density(GammaInverse("x",a,b))(x)`. ✓

## F5 — Erlang/Gamma now exact, not float  **[CONFIRM — resolves L4]**

- **input:** `cdf(Erlang("x", 1, 1))(1)`.
- **observed (V1):** `lowergamma(1, 1)/gamma(1) = (1 - exp(-1))/1 = 1 - exp(-1)` (exact),
  because `lowergamma(1, z)` auto-evaluates to `1 - exp(-z)` and `gamma(1)=1`.
- **expected (L4):** an exact expression, *not* the V0 float `0.632120558828558`. ✓

## F6 — `meijerg=True` integration path is preserved  **[CONFIRM — frame L7]**

- **input:** `cdf(Gamma("x", k, theta), meijerg=True)(z)` and the analogous Erlang doctest.
- **observed:** kwargs is non-empty, so `cdf` skips `_cdf` and calls
  `compute_cdf(meijerg=True)`; output is the pre-existing `lowergamma`-via-meijerg Piecewise.
  The added `_cdf` does **not** perturb these doctests. ✓ Trace: SPEC §6 (FRAME-meijerg).

## F7 — UniformSum cannot be verified by *symbolic* differentiation  **[METHOD]**

- **input:** `cdf(UniformSum("x", n))(x).diff(x)` with symbolic `x`.
- **observed:** an **unevaluated** `Derivative(Sum(...), x)`. Reason: `Sum._eval_derivative`
  (`sympy/concrete/summations.py:248-251`) returns `None` when the differentiation variable
  occurs in a limit, and the upper limit is `floor(x)`.
- **expected for a test:** the pdf `Sum`. The two are **equal as functions for non-integer
  `x`** (§5), but SymPy will not produce that equality symbolically.
- **classification:** *not a code bug* — it is a verification-method constraint. The CDF
  formula is the canonical Irwin–Hall CDF and is correct. The issue's prescribed test method
  ("numeric comparison at a few random floats") sidesteps this: at a concrete non-integer
  `x`, `floor(x)` is a constant, the `Sum` differentiates termwise, and `F'(x)=f(x)` holds
  numerically. **Keep** value/numeric tests for UniformSum; do **not** rely on a symbolic
  `diff(cdf)==pdf` assertion. Trace: SPEC §5, PO-D-UNIFORMSUM, ITERATION_GUIDANCE G1.

## F8 — StudentT derivative is not closed-form-simplifiable  **[METHOD]**

- **input:** `simplify(cdf(StudentT("x", nu))(x).diff(x) - density(StudentT("x", nu))(x))`.
- **observed:** SymPy does not reduce this to `0` symbolically for symbolic `nu` (it requires
  a Gauss hypergeometric contiguous-function identity SymPy does not apply automatically).
- **expected:** `0`. It **is** `0` analytically (proved via the `nu=1` Cauchy reduction and
  the standard t-CDF formula) and numerically for concrete `nu`.
- **classification:** *not a code bug*; the `hyper` form is exactly what the issue asked for
  ("expressed in terms of hypergeometric function"). Verify numerically with a concrete `nu`
  (e.g. `nu=10`). Trace: SPEC (STUDENTT) `[numeric]`, PO-D-STUDENTT.

## F9 — Distributions lack parameter-validation `check` methods  **[PRE-EXISTING]**

- `Arcsin` (no `a < b` check), `Dagum`, `Frechet`, `Laplace`, `Logistic`, `StudentT`,
  `UniformSum` define no `check`, so e.g. `Arcsin("x", 5, 1)` (with `a>b`) is constructible and
  its pdf/cdf are then nonsense (`sqrt` of a negative product, etc.).
- **classification:** pre-existing in the repository (the *pdf*s already assume validity); the
  added `_cdf` inherits the same precondition. **Out of scope** for this issue (which is about
  evaluating the CDF, not validating parameters); the `_cdf` contracts in SPEC §4 state these
  as explicit `requires`. Recorded so the precondition is not silently assumed. Trace:
  ITERATION_GUIDANCE G3.

## F10 — Class-level `set` vs. true support can disagree (Frechet, Dagum)  **[PRE-EXISTING]**

- `FrechetDistribution.set = Interval(0, oo)` but the true support is `(m, ∞)`; `DagumDistribution`
  inherits the default `Interval(-oo, oo)` though support is `(0, ∞)`.
- **impact on this fix:** none. `_cdf` is consulted directly by `cdf` and uses the *correct*
  support guard (`x > m`, `x >= 0`) independent of `set`. The added `_cdf` actually *bypasses*
  the latent `set` mismatch that would have mislocated the integration lower bound. Recorded
  as pre-existing. Trace: ITERATION_GUIDANCE G3.

## F11 — `S(x)` wrapper in Dagum/Gamma is a redundant no-op  **[CONFIRM — cosmetic]**

- In `(S(x)/b)**-a` (Dagum) and `lowergamma(k, S(x)/theta)` (Gamma), `x` is always the
  symbolic Lambda variable, so `S(x) == x`. Harmless; left as-is to match the surrounding
  precomputed-CDF style. No behavioral effect.

---

## Proof-derived findings (added by /verify)

See PROOF.md. Summary: all 11 derivative obligations PO-D-* discharge (8 in closed form, 1
numeric for StudentT, 1 termwise-loop for UniformSum); all boundary obligations PO-B-* hold
after the F1 fix; the dispatch/frame obligations PO-DISP / PO-FRAME hold by inspection of
`crv.py:214-220`. No obligation is left blocked except the **explicitly scoped** symbolic
limitations F7/F8, which are verification-method (not code) gaps and are routed to numeric
checks.
