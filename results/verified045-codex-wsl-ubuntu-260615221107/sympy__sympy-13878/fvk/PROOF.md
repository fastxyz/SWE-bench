# FVK Proof

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were executed.

## What Is Proved

Under the documented parameter domains for each distribution, V1 satisfies the
intent that default `cdf(X)(x)` returns a precomputed symbolic CDF for every
distribution named in the issue. The proof is partial correctness: if the
method call returns, the returned expression is the intended CDF. Termination
and downstream simplification performance are not machine-proved.

## Proof Outline

1. Dispatch proof. By `repo/sympy/stats/crv.py:214`, default `cdf` calls
   `_cdf(x)` and returns its result when non-`None`. V1 provides non-`None`
   `_cdf` methods for all named distribution classes, and Gamma covers Erlang.
   This discharges PO-1 and PO-4.

2. Formula proof. For each named distribution, the in-support CDF branch
   differentiates to the existing `pdf` method. The derivative obligations are
   enumerated in PO-2. This establishes that each returned formula has the
   correct density on support.

3. Boundary proof. The `Piecewise` branches in V1 return zero below support and
   one above bounded supports. For unbounded supports, the lower branch gives
   zero and the in-support formula has the standard limiting behavior. This
   discharges PO-3.

4. Compatibility proof. V1 adds methods and imports but does not change public
   constructor signatures or the `cdf(..., **kwargs)` fallback behavior. This
   discharges PO-5.

## Distribution Proof Notes

- Arcsin: the derivative of the arcsin branch reduces to the PDF after the
  identity `1 - ((2*x-a-b)/(b-a))**2 = 4*(x-a)*(b-x)/(b-a)**2`.
- Dagum: with `t = (x/b)**a`, the CDF is `(1 + 1/t)**(-p)`, whose derivative
  is `a*p*t**p/(x*(1+t)**(p+1))`, matching the PDF.
- Gamma and Erlang: the derivative rule for `lowergamma(k, z)` with
  `z = x/theta` gives the Gamma density; Erlang substitutes `theta = 1/l`.
- Frechet: the chain rule on `exp(-y**(-a))`, `y = (x-m)/s`, gives the PDF.
- GammaInverse: the derivative rule for `uppergamma(a, z)`, with
  `z = b/x`, gives the inverse-Gamma density.
- Kumaraswamy, Laplace, and Logistic: direct elementary differentiation gives
  the class PDFs.
- Nakagami: the lowergamma chain rule with `z = mu*x**2/omega` gives the PDF.
- StudentT: the standard hypergeometric antiderivative of
  `(1 + x**2/nu)**(-(nu+1)/2)` gives the StudentT branch in V1.
- UniformSum: termwise differentiation of the finite sum branch gives the
  existing finite-sum PDF away from integer breakpoints, where the CDF remains
  continuous.

## Adequacy Check

The formal English in this proof matches `fvk/SPEC.md`:

- It proves precomputed `_cdf` dispatch for the full family in INT-3, not only
  the reproduction inputs.
- It uses symbolic lowergamma, uppergamma, hyper, elementary, and finite-sum
  forms required by INT-4 and INT-5.
- It includes support and endpoint branches required by INT-6.
- It does not use legacy integration output as an oracle; those outputs are the
  bug symptoms described by the issue.

## Residual Risk

- The proof is constructed from algebra and source inspection only. It is not
  machine-checked.
- No tests were run and no hidden evaluator information was used.
- A full K proof over real SymPy expression semantics would require a larger
  semantics than the FVK fast path provides. This is recorded as F-5, a proof
  capability gap, not as a V1 source defect.

## Machine-Check Commands Not Run

These commands are recorded for the FVK honesty gate. They were not executed.

```sh
kompile fvk/mini-sympy-cdf.k --backend haskell
kast --backend haskell fvk/sympy-cdf-spec.k
kprove fvk/sympy-cdf-spec.k
```

Expected result after materializing faithful abstract CDF semantics and claims:
`kprove` returns `#Top`.
