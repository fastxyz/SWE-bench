# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Default CDF Dispatch Uses `_cdf`

Claim: for a distribution instance `D`, `D.cdf(x)` with no keyword arguments
returns `D._cdf(x)` when that method returns a non-`None` value; otherwise it
falls back to `compute_cdf`.

Evidence: `repo/sympy/stats/crv.py:214` checks `len(kwargs) == 0`,
then calls `_cdf(x)` and returns it if not `None`.

Discharge condition: every named distribution must now have an `_cdf` method
that returns a symbolic expression for in-scope default calls.

## PO-2: In-Support Formula Derivatives Match PDFs

For each distribution, prove on the documented support that `d/dx CDF(x) =
PDF(x)`.

- Arcsin: derivative of
  `1/2 + asin((2*x - a - b)/(b - a))/pi` is
  `1/(pi*sqrt((x-a)*(b-x)))`.
- Dagum: derivative of `(1 + (x/b)**(-a))**(-p)` is
  `a*p/x * (x/b)**(a*p) / (((x/b)**a + 1)**(p + 1))`.
- Gamma: derivative of `lowergamma(k, x/theta)/gamma(k)` is
  `x**(k-1)*exp(-x/theta)/(gamma(k)*theta**k)`.
- Erlang: follows from Gamma with `theta = 1/l`.
- Frechet: derivative of `exp(-((x-m)/s)**(-a))` is
  `a/s*((x-m)/s)**(-1-a)*exp(-((x-m)/s)**(-a))`.
- GammaInverse: derivative of `uppergamma(a, b/x)/gamma(a)` is
  `b**a*x**(-a-1)*exp(-b/x)/gamma(a)`.
- Kumaraswamy: derivative of `1 - (1 - x**a)**b` is
  `a*b*x**(a-1)*(1 - x**a)**(b-1)`.
- Laplace: differentiating the two branches gives
  `exp(-Abs(x-mu)/b)/(2*b)`.
- Logistic: derivative of `1/(1 + exp(-(x-mu)/s))` is
  `exp(-(x-mu)/s)/(s*(1 + exp(-(x-mu)/s))**2)`.
- Nakagami: derivative of `lowergamma(mu, mu*x**2/omega)/gamma(mu)` is
  `2*mu**mu*x**(2*mu-1)*exp(-mu*x**2/omega)/(gamma(mu)*omega**mu)`.
- StudentT: derivative of
  `x*hyper((1/2, (nu+1)/2), (3/2,), -x**2/nu)` is
  `(1 + x**2/nu)**(-(nu+1)/2)`, so the CDF derivative is the StudentT PDF.
- UniformSum: differentiating the finite sum branch termwise gives
  `1/(n-1)! * Sum((-1)**k*binomial(n,k)*(x-k)**(n-1),
  k=0..floor(x))` away from integer breakpoints, matching the PDF branch.

## PO-3: Support Branches Are Correct

Claim: CDFs return 0 below their lower support, return 1 above bounded upper
support, and avoid evaluating singular in-support formulas at excluded lower
endpoints.

Discharge points:

- Arcsin: `0` for `x < a`; `1` for `x > b`.
- Dagum, GammaInverse: formula only for `x > 0`; `0` otherwise.
- Gamma, Nakagami: formula for `x >= 0`; `0` otherwise.
- Frechet: formula only for `x > m`; `0` otherwise.
- Kumaraswamy: `0` for `x <= 0`; formula through `x <= 1`; `1` above.
- UniformSum: `0` for `x <= 0`; finite sum through `x <= n`; `1` above.
- Laplace, Logistic, StudentT: all-real supports, with continuous all-real CDFs.

## PO-4: Erlang Is Covered By Gamma

Claim: `Erlang(name, k, l)` returns `rv(name, GammaDistribution, (k, 1/l))`,
so the Gamma `_cdf` is the Erlang `_cdf` after substituting `theta = 1/l`.

Expected result: `lowergamma(k, l*x)/gamma(k)` for `x >= 0`.

## PO-5: Public Compatibility

Claim: V1 is additive and compatible.

Discharge points:

- No public constructor signatures changed.
- `SingleContinuousDistribution.cdf` behavior with kwargs is unchanged because
  `_cdf` dispatch is bypassed when kwargs are provided.
- Test files were not modified.
- Added imports are public SymPy exports already used by similar code paths.

## PO-6: Honesty and Tooling Boundary

The following commands are the kind of machine-check step a full FVK run would
emit after materializing a mini SymPy-CDF semantics and spec file. They were not
run because the task forbids K tooling:

```sh
kompile fvk/mini-sympy-cdf.k --backend haskell
kast --backend haskell fvk/sympy-cdf-spec.k
kprove fvk/sympy-cdf-spec.k
```

Expected machine-checked outcome, if the abstract CDF semantics and claims are
faithfully materialized: `kprove` returns `#Top`. Current status: constructed,
not machine-checked.
