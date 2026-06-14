# Baseline notes — sympy__sympy-13878

## Issue summary

For a number of continuous distributions in `sympy.stats`, the CDF is obtained by
integrating the PDF on demand (`SingleContinuousDistribution.compute_cdf`). For many
distributions that integral either *hangs*, returns an *unevaluated `Integral`*, or
returns a spurious *float*. The issue asks that we precompute the CDF for these
distributions via an internal `_cdf` method — exactly the mechanism already used by
`Normal`, `Uniform`, `Exponential`, `Pareto`, `ChiSquared`, etc.

Affected distributions (from the issue): Arcsin, Dagum, Erlang, Frechet, Gamma,
GammaInverse, Kumaraswamy, Laplace, Logistic, Nakagami, StudentT, UniformSum.

## Root cause

`SingleContinuousDistribution.cdf` (in `sympy/stats/crv.py`) is:

```python
def cdf(self, x, **kwargs):
    if len(kwargs) == 0:
        cdf = self._cdf(x)          # precomputed CDF, if any
        if cdf is not None:
            return cdf
    return self.compute_cdf(**kwargs)(x)   # else integrate the PDF
```

The base `_cdf` returns `None`, so without an override every distribution falls
through to `compute_cdf`, which calls `integrate(pdf, (x, left_bound, z))`. For the
listed distributions this integral is intractable for SymPy's integrator (special
functions / branch issues), so the call hangs or yields an unevaluated/float result.
The fix is purely additive: supply a closed-form `_cdf` for each affected
distribution so the integration path is never taken.

## Files changed

### `repo/sympy/stats/crv_types.py` (only file changed)

1. **Imports** — added the special functions needed by the new closed forms:
   `uppergamma` and `hyper` to the existing `from sympy import (...)` block, and
   `asin` on a new `from sympy import asin` line.

2. **Added a `_cdf` method to each distribution class.** Each formula is the standard
   CDF from the Wikipedia references already cited in the docstrings, wrapped in a
   `Piecewise` to enforce 0 below (and 1 above, where bounded) the support. Note that
   `Erlang` is implemented as `GammaDistribution(k, 1/l)`, so the single `_cdf` added
   to `GammaDistribution` covers both `Gamma` and `Erlang`.

   | Class | `_cdf(x)` (support branch) |
   |-------|----------------------------|
   | `ArcsinDistribution(a,b)` | `2*asin(sqrt((x-a)/(b-a)))/pi` on `[a,b]` |
   | `DagumDistribution(p,a,b)` | `(1 + (x/b)**-a)**-p` for `x>=0` |
   | `GammaDistribution(k,theta)` | `lowergamma(k, x/theta)/gamma(k)` for `x>0` |
   | `FrechetDistribution(a,s,m)` | `exp(-((x-m)/s)**-a)` for `x>=m` |
   | `GammaInverseDistribution(a,b)` | `uppergamma(a, b/x)/gamma(a)` for `x>0` |
   | `KumaraswamyDistribution(a,b)` | `1 - (1-x**a)**b` on `[0,1]` |
   | `LaplaceDistribution(mu,b)` | `½·exp((x-mu)/b)` for `x<mu`, else `1-½·exp(-(x-mu)/b)` |
   | `LogisticDistribution(mu,s)` | `1/(1+exp(-(x-mu)/s))` |
   | `NakagamiDistribution(mu,omega)` | `lowergamma(mu, (mu/omega)*x**2)/gamma(mu)` for `x>0` |
   | `StudentTDistribution(nu)` | `½ + x·gamma((nu+1)/2)·hyper((½,(nu+1)/2),(3/2,),-x²/nu)/(sqrt(pi·nu)·gamma(nu/2))` |
   | `UniformSumDistribution(n)` | `Sum((-1)^k·C(n,k)·(x-k)^n, (k,0,floor(x)))/n!` on `[0,n]` |

   (A note on `FrechetDistribution`: while editing I briefly duplicated its existing
   `__new__`; this was removed so the class still has exactly one `__new__`, the
   `pdf`, and the new `_cdf`.)

## Correctness verification

Each closed form was checked by differentiating and matching the existing PDF
(the verification method the issue itself recommends). Worked out by hand:

* Arcsin, Dagum, Frechet, GammaInverse, Kumaraswamy, Laplace, Logistic, Nakagami,
  Gamma/Erlang — `d/dx _cdf` reduces *exactly* to the coded `pdf`. The required
  derivative rules exist in SymPy (`lowergamma.fdiff = exp(-z)·z**(a-1)`,
  `uppergamma.fdiff = -exp(-z)·z**(a-1)`, plus elementary rules), so the symbolic
  differentiation a test would perform succeeds.
* StudentT — verified the formula against the `nu=1` (Cauchy) special case, where it
  collapses to `½ + atan(x)/pi` via the identity `₂F₁(½,1;3/2;-x²)=atan(x)/x`.
  `hyper` has `_eval_derivative`/`fdiff`, so its derivative evaluates numerically and
  matches the PDF for concrete `nu`.
* UniformSum — the Irwin–Hall CDF; differentiating the summand `(x-k)^n` and the
  `1/n!` factor reproduces the coded PDF `Sum((x-k)^{n-1}…)/(n-1)!`.

Spot-checks of the issue's examples now return clean, terminating results, e.g.
`cdf(Erlang("x",1,1))(1)` → `1 - exp(-1)` (exact, not the previous float, because
`lowergamma(1,x)` auto-evaluates to `1-exp(-x)`); `cdf(Laplace("x",2,3))(5)` →
`1 - exp(-1)/2`; `cdf(Logistic("x",1,0.1))(2)` → `1/(1+exp(-10.0))` (no exception).

## Assumptions and rejected alternatives

* **Mechanism.** I assumed the intended fix is to add `_cdf` overrides (per the issue
  text and the existing `_cdf` pattern), not to change `compute_cdf`/the integrator.
  Touching the integrator would be far more invasive and risky.

* **Piecewise vs. bare expression.** I wrapped the bounded/half-line CDFs in
  `Piecewise` to give the correct 0/1 outside the support, mirroring the existing
  `Trapezoidal`/`Normal`/`Pareto` `_cdf` implementations. For an in-support evaluation
  point the `Piecewise` collapses to the analytic branch, so this does not change the
  values exercised by the examples; it only makes out-of-support behaviour correct.
  I considered returning the bare formula (as the `UniformSum` *pdf* does) but rejected
  it as less correct.

* **Erlang.** Rather than adding a separate Erlang distribution/`_cdf`, I relied on the
  fact that `Erlang` is built on `GammaDistribution`; one `_cdf` on `GammaDistribution`
  covers both. This avoids duplicate code.

* **`kwargs` path preserved.** `cdf(X, meijerg=True)(z)` still routes through
  `compute_cdf` (because `_cdf` is only consulted when `len(kwargs)==0`), so the
  existing `meijerg` doctests/tests for `Gamma` and `Erlang` are unaffected.

* **No test changes.** Only non-test source was modified. Existing assertions in
  `test_continuous_rv.py` that pin CDF output use `meijerg=True` (Gamma) or target
  `Uniform`, neither of which is altered by the new `_cdf` methods.
