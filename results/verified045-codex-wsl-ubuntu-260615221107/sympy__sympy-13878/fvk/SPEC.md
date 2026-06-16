# FVK Specification: sympy__sympy-13878

Status: constructed from public intent and static source inspection; not
machine-checked and not executed.

## Scope

The audited behavior is `cdf(X)(x)` for the continuous distributions named in
`benchmark/PROBLEM.md`. In `SingleContinuousDistribution.cdf`, a
distribution-specific `_cdf(x)` result is returned before the integration
fallback when no keyword arguments are supplied
(`repo/sympy/stats/crv.py:214`). Therefore the intended repair point is each
affected distribution class in `repo/sympy/stats/crv_types.py`.

## Public Intent Ledger

- INT-1, source `prompt`: "Precompute the CDF of several distributions where
  integration doesn't work well."
  Obligation: each listed distribution should provide an internal `_cdf` method
  instead of relying on symbolic integration.
  Status: encoded by PO-1 and PO-2.

- INT-2, source `prompt`: "This often doesn't work well because integration is
  hard. In such cases we should have an internal `_cdf` method with a
  precomputed CDF."
  Obligation: default `cdf(X)(x)` calls for the listed examples should not hang,
  return unevaluated integrals, or raise due to integration.
  Status: encoded by PO-1.

- INT-3, source `prompt`: the issue lists Arcsin, Dagum, Erlang, Frechet,
  Gamma, GammaInverse, Kumaraswamy, Laplace, Logistic, Nakagami, StudentT, and
  UniformSum.
  Obligation: the full named family is in scope, not only one reproduction.
  Status: encoded by PO-2.

- INT-4, source `prompt`: "The CDF is directly expressed in terms of
  lowergamma" for Erlang and Gamma, "uppergamma" for GammaInverse, and
  "hypergeometric function" for StudentT.
  Obligation: special-function CDFs should remain symbolic, not be forced
  through numeric integration.
  Status: encoded by PO-2.

- INT-5, source `prompt`: "CDF has a simple formula, with no special
  functions" for Dagum, Frechet, Kumaraswamy, Laplace, and Logistic; Arcsin is
  named for an arcsin CDF; UniformSum is a finite sum similar to its PDF.
  Obligation: these CDFs should be closed forms using elementary functions or a
  finite `Sum`.
  Status: encoded by PO-2.

- INT-6, source `source-docstrings`: affected distribution docstrings state
  supports and parameter domains, for example `x in [a,b]` for Arcsin,
  `x > 0` for Dagum, `x >= m` for Frechet, `x in [0,1]` for Kumaraswamy, and
  `x in [0,n]` for UniformSum.
  Obligation: CDF branches should return 0 below support and 1 above bounded
  support, and avoid evaluating singular formulas at excluded endpoints.
  Status: encoded by PO-3.

- INT-7, source `implementation`: `Erlang` constructs a `GammaDistribution`
  with parameters `(k, 1/l)` at `repo/sympy/stats/crv_types.py`.
  Obligation: a correct Gamma `_cdf` discharges the Erlang issue case.
  Status: encoded by PO-4.

## Intent-Only Contract

For documented positive shape/scale parameters and real evaluation point `x`,
default `cdf` for the named distributions must return the following symbolic
CDFs without invoking integration:

- Arcsin(a, b): `0` for `x < a`, `1/2 + asin((2*x - a - b)/(b - a))/pi` for
  `a <= x <= b`, and `1` for `x > b`.
- Dagum(p, a, b): `0` for `x <= 0`, and
  `(1 + (x/b)**(-a))**(-p)` for `x > 0`.
- Gamma(k, theta): `0` for `x < 0`, and
  `lowergamma(k, x/theta)/gamma(k)` for `x >= 0`.
- Erlang(k, l): same as Gamma with `theta = 1/l`, yielding
  `lowergamma(k, l*x)/gamma(k)` on `x >= 0`.
- Frechet(a, s, m): `0` for `x <= m`, and
  `exp(-((x - m)/s)**(-a))` for `x > m`.
- GammaInverse(a, b): `0` for `x <= 0`, and
  `uppergamma(a, b/x)/gamma(a)` for `x > 0`.
- Kumaraswamy(a, b): `0` for `x <= 0`,
  `1 - (1 - x**a)**b` for `0 < x <= 1`, and `1` for `x > 1`.
- Laplace(mu, b): `exp((x - mu)/b)/2` for `x < mu`, and
  `1 - exp(-(x - mu)/b)/2` for `x >= mu`.
- Logistic(mu, s): `1/(1 + exp(-(x - mu)/s))` for all real `x`.
- Nakagami(mu, omega): `0` for `x < 0`, and
  `lowergamma(mu, mu*x**2/omega)/gamma(mu)` for `x >= 0`.
- StudentT(nu): `1/2 + x*hyper((1/2, (nu + 1)/2), (3/2,), -x**2/nu) /
  (sqrt(nu)*beta(1/2, nu/2))` for all real `x`.
- UniformSum(n): `0` for `x <= 0`, `1/n! * Sum((-1)**k*binomial(n,k)*
  (x-k)**n, k=0..floor(x))` for `0 < x <= n`, and `1` for `x > n`.

## Compatibility Contract

No public constructor signatures, return protocols, or test files should change.
The only production behavior change should be that default CDF requests for the
listed distributions return their precomputed formulas rather than falling back
to integration. Existing opt-in integration through `cdf(..., **kwargs)` remains
available because `SingleContinuousDistribution.cdf` only calls `_cdf` when no
keyword arguments are supplied.
