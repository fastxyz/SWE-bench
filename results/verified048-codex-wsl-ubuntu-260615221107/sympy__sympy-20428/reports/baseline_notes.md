# Baseline Notes

## Root Cause

`Poly.clear_denoms()` delegates to `DMP.clear_denoms()`, which delegates to
`dmp_clear_denoms()`/`dup_clear_denoms()` in `sympy.polys.densetools`.
When clearing denominators over `EX`, multiplying a coefficient by the common
denominator can simplify an expression that was not previously recognized as
zero into `EX(0)`. The dense helper then returned that list unchanged. For a
univariate constant polynomial this produced `[EX(0)]`, and `DMP.per()` wrapped
that list directly without validation because the polynomial level was already
known. The result printed as zero but was not represented as the canonical dense
zero `[]`, so methods that rely on canonical dense forms behaved incorrectly.

## Changed Files

`repo/sympy/polys/densetools.py`

- Imported the existing recursive dense-strip helper from `densebasic`.
- Made `dup_clear_denoms()` strip its dense result after denominator clearing,
  so a leading coefficient that simplifies to zero becomes the canonical
  univariate zero representation.
- Made `dmp_clear_denoms()` recursively strip its dense result after denominator
  clearing, so the same canonicalization also applies to multivariate dense
  polynomials whose inner coefficient polynomials simplify to zero.

## Assumptions and Alternatives

- I assumed the correct invariant is that `clear_denoms()` should return
  canonical dense polynomial representations, matching the behavior expected by
  `Poly.is_zero`, `terms_gcd()`, and other dense polynomial methods.
- I considered changing generic ground multiplication (`dup_mul_ground()` and
  `dmp_mul_ground()`), since that is where the zero coefficient is created.
  I rejected that because it would broaden the behavior change to arithmetic
  routines unrelated to denominator clearing.
- I considered fixing this only in `Poly.clear_denoms()` or `DMP.clear_denoms()`.
  I rejected that because direct callers of the dense helpers could still receive
  unstripped results from denominator clearing.
- I did not run tests or project code, as the task instructions explicitly
  prohibit execution in this benchmark session.
