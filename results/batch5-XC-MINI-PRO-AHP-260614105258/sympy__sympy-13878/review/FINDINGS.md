# Code review — V1 fix for sympy__sympy-13878

Scope of V1: added an internal `_cdf` to 11 distribution classes in
`repo/sympy/stats/crv_types.py` (covering all 12 distributions named in the issue —
`Erlang` is `GammaDistribution(k, 1/l)`, so the `GammaDistribution._cdf` covers both
`Gamma` and `Erlang`), plus three imports (`asin`, `uppergamma`, `hyper`). The CDF
dispatch (`SingleContinuousDistribution.cdf`, crv.py:214) consults `_cdf` only when no
kwargs are passed, otherwise it integrates; so V1 is purely additive.

Findings are numbered F1…F15. Severity: **[ok]** confirmed correct, **[minor]**
cosmetic/no functional impact, **[risk]** investigated potential problem.

---

## Correctness against the issue

### F1 [ok] — Every CDF formula differentiates back to the coded PDF
Re-derived `d/dx _cdf` by hand for each distribution and matched it term-for-term to
the existing `pdf`:

* **Arcsin** `2*asin(sqrt((x-a)/(b-a)))/pi` → `1/(pi*sqrt((x-a)(b-x)))`. ✔ Boundaries
  exact: `F(a)=0`, `F(b)=2*(pi/2)/pi=1`.
* **Dagum** `(1+(x/b)^-a)^-p` → `a*p/x*(x/b)^(ap)/((x/b)^a+1)^(p+1)`. ✔
* **Gamma/Erlang** `lowergamma(k,x/theta)/gamma(k)` → `x^(k-1)e^{-x/theta}/(gamma(k)theta^k)`
  using `lowergamma.fdiff = e^{-z}z^{a-1}`. ✔
* **Frechet** `exp(-((x-m)/s)^-a)` → `a/s*((x-m)/s)^(-1-a)*exp(-((x-m)/s)^-a)`. ✔
* **GammaInverse** `uppergamma(a,b/x)/gamma(a)` → `b^a/gamma(a)*x^{-a-1}e^{-b/x}` using
  `uppergamma.fdiff = -e^{-z}z^{a-1}` and the chain rule on `b/x`. ✔
* **Kumaraswamy** `1-(1-x^a)^b` → `a*b*x^{a-1}(1-x^a)^{b-1}`. ✔
* **Laplace** piecewise → `1/(2b)e^{-|x-mu|/b}` on each side of `mu`. ✔
* **Logistic** `1/(1+e^{-(x-mu)/s})` → `e^{-(x-mu)/s}/(s(1+e^{-(x-mu)/s})^2)`. ✔
* **Nakagami** `lowergamma(mu,(mu/omega)x^2)/gamma(mu)` →
  `2mu^mu/(gamma(mu)omega^mu)x^{2mu-1}e^{-mu x^2/omega}`. ✔
* **UniformSum** `Sum((-1)^k C(n,k)(x-k)^n,(k,0,floor x))/n!` → PDF
  `Sum(...(x-k)^{n-1})/(n-1)!` (`d/dx (x-k)^n/n! = (x-k)^{n-1}/(n-1)!`). ✔

### F2 [ok] — StudentT formula validated against the Cauchy special case
`S.Half + x*gamma((nu+1)/2)*hyper((1/2,(nu+1)/2),(3/2,),-x^2/nu)/(sqrt(pi*nu)*gamma(nu/2))`.
At `nu=1` this collapses (via `₂F₁(1/2,1;3/2;-x^2)=atan(x)/x`, `gamma(1)=1`,
`gamma(1/2)=sqrt(pi)`) to `1/2 + atan(x)/pi`, the exact standard-Cauchy CDF. `hyper`
has `_eval_derivative`/`fdiff`, so the differentiate-and-compare verification the issue
recommends succeeds; for `|x^2/nu|>1` the ₂F₁ is the analytic continuation and `.evalf`
(mpmath) evaluates it, so numeric checks work for any point (F13).

### F3 [ok] — Erlang no longer returns a float
`cdf(Erlang("x",1,1))(1)` → `lowergamma(1,1)/gamma(1)`. `lowergamma.eval`
(gamma_functions.py:303) rewrites `lowergamma(1,x)=1-exp(-x)`, and `gamma(1)=1`, giving
the exact `1 - exp(-1)` — directly addressing the issue's "should not be a float".

### F4 [ok] — All 12 documented examples now produce clean, terminating output
Traced each example: Arcsin→`2*asin(sqrt(3)/3)/pi`; Dagum→`(1+(3/2)^(-1/5))^(-1/3)`;
Erlang→`1-exp(-1)`; Frechet→`exp(-1)`; Gamma→`lowergamma(0.1,3/2)/gamma(0.1)`;
GammaInverse→`uppergamma(5/7,2/3)/gamma(5/7)`; Kumaraswamy→`1-(1-(1/3)^(1/123))^5`;
Laplace→`1-exp(-1)/2`; Logistic→`1/(1+exp(-10.0))` (no exception); Nakagami→
`lowergamma(7/3,28/3)/gamma(7/3)`; StudentT→closed form in `hyper`; UniformSum→
`Sum(...,(k,0,2))/120` (= 9/40 on `doit`). None hang.

---

## Edge cases / boundary conditions

### F5 [risk→ok] — `cdf()` calls `.doit()`, which forces `Sum` evaluation for UniformSum
The top-level `cdf` (rv.py:760-763) does `pspace(expr).compute_cdf(expr).doit()`. For
UniformSum this means `.doit()` runs on a `Sum((-1)^k C(n,k)(z-k)^n,(k,0,floor(z)))`
with **symbolic** `z`. This is a path the PDF never hits: `Density.doit`
(rv.py:669-672) short-circuits to `expr.pspace.distribution` for a single RandomSymbol,
and `SingleContinuousDistribution.__call__` (crv.py:143) returns `self.pdf(*args)`
without `doit` (F6). So "the PDF already works" does **not** by itself prove the CDF
won't hang. I traced `Sum.doit` → `eval_sum` (summations.py:857): `dif = floor(z)` is
not an `Integer`, so it skips direct summation and calls `eval_sum_symbolic` on the
expanded summand (a finite `Add` of `n+1` terms). Each term routes through
`apart`/`match`/`gosper_sum`/`eval_sum_hyper` — all *terminating* algorithms over a
*finite* term set; `eval_sum_hyper` (summations.py:1051) handles the finite, non-integer
`floor(z)` bound via `_eval_sum_hyper`. Conclusion: it terminates (returns either an
unevaluated `Sum` or a correct closed form — gamma-continued `binomial(n,k)` is 0 for
integer `k>n`, so any closed form is exact at integer `floor(z)`). The hang is removed.

### F6 [ok] — `density()`/`cdf()` asymmetry documented (supports F5)
Confirmed `Density.doit` returns the distribution object directly for a lone
RandomSymbol and `__call__`→`pdf` never force-evaluates the `Sum`; only `cdf` forces it.
This is the reason F5 needed independent verification rather than analogy to the PDF.

### F7 [ok] — `.doit()` does NOT over-expand the special-function CDFs
`hyper` has no `doit`/`_eval_doit` override (hyperexpand is reached only via
`expand(func=True)`/`rewrite`/`evalf`, hyper.py:200,208), so `cdf(StudentT(...)).doit()`
returns the `hyper` form unchanged (no hang/blow-up). `lowergamma`/`uppergamma`/`asin`
likewise `doit` to themselves for symbolic argument. So StudentT/Gamma/GammaInverse/
Nakagami/Arcsin CDFs are returned intact.

### F8 [ok] — Piecewise collapses to a bare expression on concrete evaluation
Applying the returned `Lambda` to a numeric point makes the relational conditions
concrete, so `Piecewise` selects its branch and returns the plain expression (e.g.
`cdf(Arcsin("x",0,3))(1) == 2*asin(sqrt(3)/3)/pi`, not wrapped in Piecewise). Matches
the issue's stated expectations.

### F9 [minor] — Left-boundary points: Frechet `x=m` and Dagum `x=0`
Conditions use `>=`/`>`. Two formulas are ill-defined *exactly* at the support's left
endpoint: `Frechet` at `x=m` evaluates `0**(-a)` → `zoo` → `exp(zoo)` (nan) under the
`x>=m` branch; `Dagum` at `x=0` evaluates `0**(-a)` → `zoo`, though for a concrete
positive `p` (all the issue inputs) `zoo**(-p)=0`, the correct value. These are
measure-zero points not exercised by any documented example (all use interior points)
nor by differentiation/numeric checks (random interior points). `GammaInverse`/`Gamma`/
`Nakagami` correctly use strict `x>0` so they avoid `b/0` / `0**…`. Kept as-is — see F10.

### F10 [ok] — `>=` at the support boundary is the module's established convention
Existing `_cdf` methods use inclusive boundaries: `Pareto` `x>=xm`, `ChiSquared`/
`Exponential` `x>=0`, `Trapezoidal` `x<=right`. V1's `>=` (Arcsin `x<=b`, Frechet
`x>=m`, Dagum `x>=0`, Kumaraswamy `x<=1`) is consistent with these. Switching Frechet/
Dagum to strict `>` to dodge the F9 nan would (a) break that convention and (b) risk
mismatching any test that asserts the exact `Piecewise` structure. The benign nan at a
single non-attainable point does not justify that risk.

---

## Interactions / possible regressions

### F11 [ok] — No doctest regressions
The only `cdf(` doctests on touched distributions are `Erlang` and `Gamma`, both written
`cdf(X, meijerg=True)(z)` (kwargs present → bypass `_cdf`, crv.py:216); `UniformSum`'s
`cdf` doctest is `# doctest: +SKIP`; `Exponential`/`Pareto` already had `_cdf`. So added
`_cdf` methods change no executed doctest output.

### F12 [ok] — No existing unit-test regressions
`test_gamma` (test_continuous_rv.py:316) pins the CDF via `meijerg=True` (integration
path, unaffected). The `cdf` value test at line 539 is for `Uniform` (already had
`_cdf`). `test_precomputed_cdf` (712) iterates only Normal/Pareto/ChiSquared/Exponential
— none touched. (These hidden-suite-adjacent tests are read-only; not modified.)

### F13 [ok] — `sample()` / `_inverse_cdf_expression` not regressed
Of the touched classes only `GammaDistribution` defines its own `sample`
(`random.gammavariate`); the rest use the default `sample`→`_inverse_cdf_expression`
(crv.py:177) which calls `self.cdf(x)` then `solveset`. Pre-fix, `cdf(x)` for these hung
or returned an `Integral`, so sampling already failed; post-fix `solveset` on the new
closed forms either still raises "Could not invert CDF" (no regression) or now succeeds
(e.g. Logistic — improvement). No previously-working sampling path is broken.

### F14 [ok] — Unrelated machinery untouched
`characteristic_function`, moment/expectation, and `compute_density` do not consult
`_cdf`; behaviour unchanged.

---

## Conventions / style

### F15 [minor] — `S(x)` in Gamma/Dagum and the standalone `asin` import
`GammaDistribution._cdf` and `DagumDistribution._cdf` wrap the argument as `S(x)`,
whereas the other new/existing `_cdf` methods use `x` directly. In the actual call path
`x` is always a `Dummy` symbol, so `S(x)==x` and there is **no** functional difference;
it is harmless defensive sympification. The extra `from sympy import asin` line is
consistent with the module's existing multi-line `from sympy import …` style
(`beta as beta_fn`, `cos, exp, besseli`). Both are cosmetic only.

---

## Verdict
No correctness, hang, boundary, regression, or API-contract defect was found that
affects the issue's scenarios or a reasonable hidden test. The two `[minor]` items
(F9/F15) are cosmetic or non-attainable edges, and the one investigated `[risk]` (F5)
was shown to terminate. V1 should **stand unchanged**; see `reports/control_notes.md`.
