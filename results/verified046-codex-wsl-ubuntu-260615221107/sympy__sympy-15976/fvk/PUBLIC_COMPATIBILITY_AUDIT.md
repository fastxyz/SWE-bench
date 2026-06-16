# Public Compatibility Audit

## Changed Public Symbols

No public function, class, method, or setting name was changed.

## Dispatch And Call Sites

- `mathml(expr, printer='presentation', **settings)` still dispatches to
  `MathMLPresentationPrinter(settings).doprint(expr)`.
- `MathMLPresentationPrinter._print_MatrixSymbol` still delegates to
  `_print_Symbol(sym, style=self._settings['mat_symbol_style'])`.
- `_print_RandomSymbol` still aliases `_print_Symbol`.
- Internal callers append the returned DOM node into MathML containers; static
  search found no public source callsite that requires scripted symbols to be
  wrapped in an outer `mi`.

## Return Shape Compatibility

The intentional compatibility break is the scripted-symbol DOM shape:
`mi(msub(...))`, `mi(msup(...))`, and `mi(msubsup(...))` are replaced by the
scripted node itself. This is not treated as a regression because the public
issue identifies the old shape as the bug.

Plain-symbol return shape is preserved:

- `Symbol("x")` still returns `mi("x")`.
- Plain bold matrix symbols still return `mi("A")` with
  `mathvariant="bold"`.

## Result

No unhandled public callsite, subclass override, signature change, or setting
compatibility issue was found.
