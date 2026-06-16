# Baseline Notes

## Root cause

`sympy.printing.pycode.AbstractPythonCodePrinter._print_Mod` prints `Mod(a, b)` as Python's infix `%` operator, but the surrounding parenthesization logic still used SymPy's generic precedence for `Mod` as a function. That made `Mod(x, y)` appear to bind like a normal function call when it was embedded in larger generated Python expressions.

For `-Mod(x, y)`, the multiplication printer strips the negative coefficient and prints a leading `-` followed by the factor. Because generic precedence treated the `Mod` factor as high precedence, no parentheses were added, producing `-x % y`. Python parses that as `(-x) % y`, not as `-(x % y)`.

## Changed files

`repo/sympy/printing/pycode.py`

Added Python-code-specific precedence handling for printed `Mod` expressions. The printer now treats `Mod` as additive-level when deciding whether a containing expression must parenthesize it, so contexts like unary minus, multiplication, and exponentiation will print the `%` expression in parentheses. The existing operand handling in `_print_Mod` is left unchanged, so operands such as `x + 1` or `y*z` are still parenthesized safely when used around `%`.

## Assumptions

The issue is about generated Python syntax from `pycode` and lambdify's Python code printer path, especially when `modules=[]` causes `Mod` to be emitted as `%` rather than a named runtime function.

The correct generated form for the direct example is a parenthesized modulo expression under unary minus, e.g. `-(x % y)`, rather than changing lambdify module selection behavior.

## Alternatives considered and rejected

Changing the global precedence table in `sympy/printing/precedence.py` was rejected because that table is shared with non-Python printers and treats `Mod` as a SymPy function in contexts where it is not emitted as Python's `%` operator.

Changing lambdify so `modules=[]` behaves like the default module list was rejected because the public hint shows the lower-level `pycode(-Mod(x, y))` bug directly. That would hide this symptom for one lambdify configuration without fixing Python code generation itself.

Changing `_print_Mod` to always wrap the whole expression was rejected as a broader formatting change than needed. The containment decision already belongs to `parenthesize`; the missing piece was the Python printer's precedence for the printed `%` form.
