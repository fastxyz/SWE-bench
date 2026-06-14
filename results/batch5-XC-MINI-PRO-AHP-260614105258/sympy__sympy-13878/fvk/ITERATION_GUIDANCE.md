# ITERATION_GUIDANCE.md — feedback for the next generate→formalize→verify pass

Each entry: **Evidence** (claim/VC/finding) · **Classification** · **UltimatePowers question**
(next intent question) · **Recommended change** · **Tests**.

---

## G0 — APPLIED THIS PASS: Frechet boundary fix (Finding F1)

- **Evidence:** PO-B-FRECHET failed under `x>=m` (`F(m)=exp(-zoo)=nan`); SPEC (FRECHET)
  boundary clause / intent L8.
- **Classification:** code bug (wrong value at an in-domain point) — **fixed**.
- **Change made:** `repo/sympy/stats/crv_types.py`, `FrechetDistribution._cdf`, guard
  `x >= m` → `x > m`. Now `F(m)=0`; interior/test values unchanged.
- **Tests:** add/keep `cdf(Frechet("x", S(4)/3, 1, 2))(2) == 0` (boundary) alongside the
  interior `…(3) == exp(-1)`.

## G1 — UniformSum: symbolic differentiation stalls on `floor(x)` in the `Sum` limit (F7)

- **Evidence:** `Sum._eval_derivative` returns `None` when the diff variable is in a limit
  (`summations.py:248-251`); the CDF/PDF upper limit is `floor(x)`. So
  `diff(cdf(UniformSum)(x), x)` is an unevaluated `Derivative`, never the pdf `Sum`.
- **Classification:** proof-capability / test-method gap (the *formula* is the correct
  Irwin–Hall CDF; only the symbolic check is blocked).
- **UltimatePowers question:** "For the discrete-knot distributions (Irwin–Hall), is
  termwise/numeric differentiation acceptable as the correctness oracle, or do you want a
  closed-form CDF (e.g. a `Piecewise` over the `n` integer cells) that *does* differentiate
  symbolically?"
- **Recommended change (optional, future):** none required for correctness. If a
  symbolically-differentiable form is ever wanted, expand the `Sum` into the `n`-cell
  `Piecewise` on `(j, j+1)` so each cell's polynomial differentiates directly — at the cost of
  a much larger expression. Not worth it for this issue.
- **Tests:** verify UniformSum by **numeric** `diff(cdf)(x).subs(x,v).doit()` at non-integer
  `v` and by value (`cdf(UniformSum("x",5))(2).doit() == S(9)/40`). Never assert
  `simplify(diff(cdf)-pdf)==0` symbolically.

## G2 — StudentT: derivative identity needs a `₂F₁` contiguity lemma (F8)

- **Evidence:** PO-D-STUDENTT; SymPy will not auto-reduce `diff(F)-f` to `0` for symbolic `nu`.
- **Classification:** proof-capability gap (correct formula; closed-form VC beyond the bundled
  simplifier — analogous to the §6/§7 "escalation boundary" in the kit).
- **UltimatePowers question:** "Is a numeric/derivative check at concrete `nu` sufficient
  evidence for the t-distribution CDF, or should the test suite also pin the `nu=1` Cauchy
  reduction `1/2 + atan(x)/pi`?"
- **Recommended change:** none to the code (the `hyper` form is exactly what the issue
  requested). Optionally add the `nu=1` analytic assertion as a cheap closed-form anchor.
- **Tests:** numeric `diff` at concrete `nu` (e.g. 10); plus the `nu=1` Cauchy equality.

## G3 — Missing `check` methods and `set`/support mismatches (F9, F10)

- **Evidence:** Arcsin (no `a<b`), Dagum/Frechet/Laplace/Logistic/StudentT/UniformSum (no
  `check`); `FrechetDistribution.set=Interval(0,oo)` vs true support `(m,∞)`; Dagum inherits
  `Interval(-oo,oo)`.
- **Classification:** pre-existing underspecified precondition / latent inconsistency; **out of
  scope** for the CDF issue (the `_cdf` correctly uses the true support guard and sidesteps the
  `set` mismatch).
- **UltimatePowers question:** "Should constructing a distribution with invalid parameters
  (`Arcsin(0,9,1)` with `a>b`, non-positive shape) raise at build time, and should `set` be
  corrected to the true support `(m,∞)` for Frechet / `(0,∞)` for Dagum?"
- **Recommended change (separate PR):** add `@staticmethod check(...)` with `_value_check`
  (mirroring `GammaDistribution.check`) and fix the `set` properties. Do **not** bundle into
  this fix.
- **Tests:** `raises(ValueError, lambda: Arcsin("x", 5, 1))` etc., kept out-of-domain.

## G4 — Dagum boundary correctness depends on `zoo**(-p)=0` (F2)

- **Evidence:** PO-B-DAGUM; `F(0)` under `x>=0` evaluates through `(1+zoo)**(-p)`.
- **Classification:** fragile-but-correct (value is `0`, the right answer).
- **UltimatePowers question:** "Do you want support-boundary evaluation to avoid indeterminate
  intermediates uniformly (guard `x>0` everywhere), even where the current result is already
  correct?"
- **Recommended change (optional):** for uniformity with the F1 fix, `x>=0`→`x>0` in Dagum.
  Deliberately **not** done this pass to keep the change minimal and avoid churn on a
  branch that already returns the correct value.
- **Tests:** if changed, `cdf(Dagum(...))(0) == 0` (already true today).

---

## Net guidance

The fix is **correct and complete for the issue's goal** (precomputed CDFs that terminate,
stay exact, and satisfy `F'=pdf`). One real bug (F1, Frechet `nan` at `x=m`) was surfaced by
the boundary obligation and **fixed**. The remaining items are (a) verification-method
constraints for the two special-function CDFs (G1/G2 — handle by numeric tests, the issue's own
prescription) and (b) pre-existing, out-of-scope hardening (G3/G4). No further code change is
warranted for this issue.
