# Baseline Notes

## Root cause

`lambdify(..., modules='mpmath')` selects `MpmathPrinter`, but that printer only had a special high-precision representation for SymPy `Float` values. It inherited the default rational printing path, which emits non-integer rationals as plain Python division such as `232/3`.

In generated mpmath lambdas, that plain division is evaluated by Python before or outside mpmath's arbitrary-precision conversion rules for the rational itself. As a result, constants like `232/3` can enter the numeric calculation with ordinary Python precision instead of the active mpmath precision.

## Files changed

`repo/sympy/printing/pycode.py`

Added `MpmathPrinter._print_Rational`. Non-integer rationals now print as `mpmath.mpf(p)/mpmath.mpf(q)` through `_module_format('mpmath.mpf')`, so lambdify output with `fully_qualified_modules=False` uses the existing `mpf` name imported from the mpmath namespace. Negative rationals keep the leading minus sign outside the `mpf(...)` call so the existing `Add` printer continues to format subtraction naturally. Integer-valued rationals still print as plain integers.

## Assumptions

The reported precision loss is specific to mpmath-backed numerical evaluation, so the fix belongs in `MpmathPrinter` rather than the shared Python code printer or generic string printer.

The existing mpmath namespace used by lambdify already imports `mpf` via `from mpmath import *`, and `_module_format('mpmath.mpf')` is the local printer convention used by `_print_Float`, so reusing it keeps import handling consistent.

I did not add or modify tests because the task forbids changing test files and running tests or project code in this environment.

## Alternatives considered and rejected

Changing `StrPrinter._print_Rational` or `CodePrinter._print_Rational` would affect unrelated printers and modules such as generic Python, NumPy, and SciPy lambdify output. That would be broader than necessary for the mpmath issue.

Changing `lambdify` namespace setup to bind `Rational` or another helper would require generated code to call SymPy or a new helper at runtime. The mpmath printer already owns module-specific numeric code generation, so printing the rational directly with `mpf` is smaller and follows the existing float handling pattern.

Wrapping rationals as decimal strings was rejected because it would add an unnecessary decimal conversion step and would be less direct than preserving the exact numerator and denominator in the generated code.
