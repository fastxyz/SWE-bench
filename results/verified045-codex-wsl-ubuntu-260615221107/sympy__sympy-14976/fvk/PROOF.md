# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, Python, or test command was executed.

## Claim Summary

The proof covers `MpmathPrinter._print_Rational` for normalized SymPy rational inputs:

- `q == 1` returns the integer numerator string.
- `q > 1, p >= 0` returns `F(p)/F(q)`, where `F = _module_format('mpmath.mpf')`.
- `q > 1, p < 0` returns `-F(abs(p))/F(q)`.

It also connects that method to the user-visible path: `lambdify(..., modules='mpmath')` selects `MpmathPrinter`, and the mpmath namespace provides unqualified `mpf`.

## K Artifacts

Supporting formal files:

- `mini-python-printer.k`
- `mpmath-rational-printer-spec.k`

These model the relevant generated-expression constructors:

- `intLit(p)` for integer output;
- `div(mpfCall(F, p), mpfCall(F, q))` for positive wrapped rationals;
- `neg(div(mpfCall(F, abs(p)), mpfCall(F, q)))` for negative wrapped rationals.

The model deliberately distinguishes bare integer division from mpmath-wrapped division, which is the property under verification.

## Symbolic Proof Sketch

1. Start from the precondition that the input is a normalized SymPy rational represented by numerator `P` and positive denominator `D`.
2. Case split on `D == 1`, `D > 1 and P >= 0`, and `D > 1 and P < 0`.
3. In the `D == 1` branch, V1 returns `str(e.p)`. The abstract K rule reaches `intLit(P)`. There is no division expression, so the reported precision bug is absent.
4. In the `D > 1 and P >= 0` branch, V1 computes `func = _module_format('mpmath.mpf')` and returns `'{func}({p})/{func}({q})'`. The abstract K rule reaches `div(mpfCall(F, P), mpfCall(F, D))`.
5. In the `D > 1 and P < 0` branch, V1 returns `'-{func}({abs_p})/{func}({q})'`. The abstract K rule reaches `neg(div(mpfCall(F, 0 -Int P), mpfCall(F, D)))`.
6. The generated non-integer rational expression therefore has mpmath-valued operands on both sides of `/`, so it is not the pre-fix bare integer division `P/D`.
7. Source inspection of `lambdify.py` discharges the integration step: mpmath modules select `MpmathPrinter`, and `from mpmath import *` populates `mpf` for the unqualified lambdify output.
8. Source inspection of the surrounding printers discharges the grouping step: rational factors/exponents are parenthesized where operator precedence requires it.

No loops or recursive calls are present in the audited code path, so no circularity claim is needed.

## Exact Machine-Check Commands

These commands were not run. They are the commands to run later from the repository root if K tooling is available:

```sh
cd fvk
kompile mini-python-printer.k --backend haskell
kast --backend haskell mpmath-rational-printer-spec.k
kprove mpmath-rational-printer-spec.k
```

Expected successful result after any needed K parser/module adjustments: `#Top`.

## Residual Risk

This proof is partial and constructed:

- It proves generated expression form, not full Python parser behavior.
- It proves dispatch into mpmath-valued division, not all final-rounding properties of mpmath for arbitrarily large rationals.
- It was not machine-checked because the task forbids running K tooling.

These risks are recorded in `FINDINGS.md` as F-003 and do not justify changing V1.

## Test Recommendation

No tests were edited. Existing or hidden tests that inspect mpmath lambdify source for non-integer rationals are covered by the constructed spec but should not be removed unless `kprove` is actually run and returns `#Top`. Tests for actual `nsolve` precision should be kept because this FVK proof does not execute mpmath or prove its internal rounding.
