# Baseline Notes

## Root cause

`Mod.eval` did not reduce an integer numeric coefficient of a symbolic integer
product when the divisor was an integer. For `Mod(3*i, 2)`, the existing
numeric and parity checks cannot decide the result, the multiplication
denesting branch only runs when one factor is already a `Mod`, and the later
coefficient handling only extracts non-rational numeric factors. As a result,
the congruence `3*i == i (mod 2)` was never used.

## Files changed

`repo/sympy/core/mod.py`

Added an integer-only coefficient reduction in the existing coefficient
handling path. When the dividend has an integer numeric coefficient, the
divisor is an integer numeric coefficient with no remaining symbolic factor,
and the rest of the dividend is known to be integer, the coefficient is reduced
modulo the divisor while leaving the product inside `Mod`. This makes
`Mod(3*i, 2)` evaluate through the existing final reconstruction as
`Mod(i, 2)`.

## Assumptions and rejected alternatives

I assumed this simplification is valid only in the integer modular arithmetic
case: the symbolic tail of the product must be known integer, and the divisor
must be a plain integer after extracting its coefficient. This avoids changing
cases with non-integer symbols, symbolic divisors such as `2*y`, or float
divisors.

I rejected the broader approach from the public issue diff that wraps every
factor in `Mod(x, q)` and distributes over the product. That approach can
incorrectly simplify terms with denominators, such as `Mod(e/2, 2)` for an even
symbol `e`, because `e/2` is not necessarily even. It can also pull reduced
numeric factors outside the outer `Mod`, which is not generally equivalent for
all integer coefficients.

I did not add or modify tests, and I did not run the test suite or execute code,
as required by the task constraints.
