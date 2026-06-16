# Intent Spec

Status: constructed from public issue text and in-repository source, not machine-checked.

## Required Behavior

1. For `lambdify(..., modules='mpmath')`, generated source for non-integer SymPy `Rational` constants must not contain a bare Python integer division literal such as `232/3`.

2. Non-integer SymPy rationals printed for the mpmath backend must be wrapped so their generated expression is evaluated by mpmath at the active mpmath precision.

3. The issue example `RisingFactorial(18, x) - 232/3` must become an equivalent expression where the rational constant `232/3` is represented as mpmath operands before division.

4. The change should be limited to mpmath lambdification. Generic Python, NumPy, SciPy, TensorFlow, and SymPy printers have no public-intent evidence requiring a changed rational format for this issue.

## Domain

The audited unit is the source-to-source printer path for SymPy rational numbers in mpmath lambdified functions:

- `lambdify` selects `MpmathPrinter` when the module list contains `mpmath`.
- `MpmathPrinter._print_Rational` receives normalized SymPy rational values with integer numerator `p` and positive integer denominator `q`.
- The primary in-domain bug class is `q > 1`.

## Default-Domain Assumptions

- SymPy `Rational` values store a normalized positive denominator. This follows from `Rational.__new__` normalizing `q < 0` by flipping both signs.
- mpmath numeric constructors such as `mpf(n)` create mpmath numeric values from integer arguments under the active mpmath precision.
- This FVK pass proves partial correctness of code generation form, not total correctness of mpmath's internal arithmetic implementation.
