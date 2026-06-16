# Baseline Notes

## Root cause

`Poly` subclasses `Expr`, but it inherited `Expr._op_priority == 10.0`. SymPy's core binary operator decorator only delegates to the right-hand operand's reflected method when the right-hand operand has strictly higher `_op_priority`. For `x*Poly(x)` and `S(-2)*Poly(x)`, the left-hand `Expr` operation therefore built an ordinary unevaluated `Mul` before `Poly.__rmul__` could convert the expression or scalar into a polynomial.

`Poly.__mul__` and `Poly.__rmul__` already contain the needed conversion logic: they try to construct a compatible `Poly` from the non-`Poly` operand and then call polynomial multiplication. The failure was that right-hand `Poly` instances were not given priority over ordinary expressions.

## Changed files

- `repo/sympy/polys/polytools.py`: added `_op_priority = 10.001` to `Poly`. This makes ordinary `Expr` operands defer mixed arithmetic to `Poly` while keeping the value only slightly above the core `Expr` default. With that dispatch, `x*Poly(x)` and `S(-2)*Poly(x)` reach `Poly.__rmul__`, which returns the evaluated polynomial when the left operand can be represented over the polynomial's generators.

## Assumptions and alternatives considered

- I assumed the intended behavior is symmetric mixed arithmetic whenever the non-`Poly` operand can be converted to a polynomial over the same generators, matching the existing behavior for `Poly(x)*x`, `Poly(x)*S(-2)`, and plain Python integer multiplication by `Poly`.
- I used a small priority increase rather than changing `Expr.__mul__` or `Mul` construction. Special-casing `Poly` in core multiplication would be broader and would duplicate the conversion rules already implemented by `Poly`.
- I did not add or modify tests because the benchmark instructions forbid changing test files and forbid running code or tests in this session.
