# Baseline Notes

## Root Cause

Matrix subtraction is represented internally as a `MatAdd` containing `MatMul`
terms with a scalar coefficient of `-1`, for example `A - B` becomes a matrix
sum with a negative matrix product term. The string, pretty, and LaTeX matrix
addition printers rendered `MatAdd` by directly joining each printed argument
with a literal plus separator. Unlike the scalar `Add` printers, they did not
inspect each term for an extractable leading minus sign, so negative matrix
terms printed as `(-1)*B`, `+ -A*B`, or `-1 B` instead of using subtraction
syntax.

## Files Changed

`repo/sympy/printing/str.py`

Updated `_print_MatAdd` to inspect each matrix-add term with
`as_coeff_mmul()`. If the scalar coefficient can extract a minus sign, the
printer emits a subtraction sign and prints the negated term, preserving the
existing `MatAdd` argument order and parenthesization behavior.

`repo/sympy/printing/latex.py`

Updated `_print_MatAdd` with the same matrix-specific sign extraction so LaTeX
matrix sums use `-` between negative terms instead of joining negative
renderings with `+`. A small first-term spacing guard preserves readable output
for LaTeX commands such as `\sqrt`.

`repo/sympy/printing/pretty/pretty.py`

Updated `_print_MatAdd` to build `prettyForm` objects that carry negative
binding for negative matrix terms, following the same pattern used by the
scalar pretty `Add` printer. This lets `prettyForm.__add__` avoid inserting a
literal plus before terms that should be rendered as subtraction.

## Assumptions and Alternatives

I treated the issue as a printing bug only. The internal `MatAdd`/`MatMul`
representation is intentional and was left unchanged.

I preserved existing `MatAdd` argument ordering. The issue report asks for
subtraction-style rendering of negative terms, not a new ordering rule.

I used `as_coeff_mmul()` rather than scalar `as_coeff_Mul()` or `_coeff_isneg`
because matrix products are represented by `MatMul`, not scalar `Mul`, and the
scalar helpers do not recognize the failing matrix terms.

I kept a fallback for matrix-like objects without `as_coeff_mmul()` so explicit
matrix arguments continue to render through the existing printer paths.

I rejected changing `MatMul` printing globally because that would affect every
matrix product context and still would not fix the literal plus separator in
`MatAdd`. I also rejected rewriting `MatAdd` as scalar `Add` for printing,
because matrix expressions have different shape validation and multiplication
semantics.
