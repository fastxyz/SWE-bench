# Public Compatibility Audit

Changed public or semi-public symbol: `LatexPrinter._print_Subs`.

Compatibility status: pass.

Audit points:

- Signature remains `def _print_Subs(self, subs)`.
- Return type remains a LaTeX string.
- Input unpacking remains `expr, old, new = subs.args`.
- Substitution-variable and substitution-point formatting is unchanged.
- No public callsite has to pass a new argument.
- No subclass or override is forced to accept a new dispatch shape.
- No tests are modified.

The only behavior change is the rendering of the substituted expression body:
it now passes through the printer's existing precedence-aware `parenthesize`
helper.
