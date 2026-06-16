# Baseline Notes

## Root cause

`LatexPrinter._print_Subs` rendered the substituted expression with
`self._print(expr)` directly. When that expression was an `Add`, the rendered
body of the `Subs` began with an unparenthesized sum, e.g.
`\left. - x + y \right|_{...}`. In a surrounding multiplication such as
`3*Subs(-x + y, ...)`, the generic multiplication printer treated `Subs` as a
single factor, but the visible LaTeX made the coefficient appear to apply only
to the first term of the substituted expression.

## Changed files

`repo/sympy/printing/latex.py`

Changed `_print_Subs` to render the substituted expression through
`self.parenthesize(expr, PRECEDENCE["Mul"], strict=True)`. This reuses the
existing precedence rules for LaTeX printing: additive or otherwise
lower-precedence expressions are wrapped, while multiplicative expressions such
as the existing `Subs(x*y, ...)` case remain unchanged.

`reports/baseline_notes.md`

Added this report as required by the task.

## Assumptions and alternatives

I assumed the desired grouping is around the expression inside the substitution
bar, matching the issue's expected form
`\left. \left(- x + y\right) \right|_{...}`, rather than wrapping the entire
`Subs` factor in an outer pair of parentheses.

I considered changing the precedence table for `Subs`, but assigning `Subs` a
lower precedence would make multiplication print an outer wrapper around the
whole substitution expression, which does not match the requested LaTeX.
Assigning it multiplication precedence would not fix the visible ambiguity.

I also considered a narrower `Add`-only special case. Using the existing
`parenthesize` helper is still targeted to the same problem, but it follows the
printer's established precedence logic and avoids duplicating bracket rules in
`_print_Subs`.

No tests or code were run, per the task instructions.
