# Baseline Notes

## Root cause

The LaTeX printer for `Subs` printed `subs.expr` directly with `self._print(expr)`.
When a `Subs` object was part of a multiplication, the outer `Mul` printer treated
the whole `Subs` object as an atomic factor and did not inspect the substituted
expression inside the evaluation bar. As a result, additive expressions such as
`-x + y` were emitted bare before `\right|`, producing ambiguous output like
`3 \left. - x + y \right|_{...}`.

## Files changed

`repo/sympy/printing/latex.py`

Changed `_print_Subs` so the substituted expression is rendered with
`parenthesize(expr, PRECEDENCE["Mul"], strict=True)`. This matches the local
LaTeX printer pattern used for expressions attached to derivative and integral
operators: additive expressions receive `\left(...\right)` while ordinary
multiplicative or atomic expressions keep their existing formatting.

## Assumptions

I assumed the issue is about the expression governed by the substitution bar,
not about wrapping the entire `Subs` object as a multiplicative factor. That
matches the requested output, which places parentheses around `- x + y` inside
`\left. ... \right|` rather than around the full substitution construct.

I assumed existing non-additive `Subs` output such as `Subs(x*y, ...)` should
remain unchanged.

## Alternatives considered and rejected

Adding a precedence rule for `Subs` was rejected because it would affect how the
whole `Subs` object is bracketed in outer expressions and would not directly
produce the requested placement of parentheses.

Changing the generic `Mul` bracket logic was rejected because the problem is
specific to how `Subs` exposes its inner expression to the LaTeX output; a global
change would risk unrelated multiplication formatting regressions.
