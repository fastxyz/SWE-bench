# Public Compatibility Audit

## Changed Public Or Virtual Dispatch Surface

`MCodePrinter` gained two printer-dispatch methods:

- `_print_Max(self, expr)`
- `_print_Min(self, expr)`

These methods match the established printer method signature pattern and are
called reflectively by `Printer._print` when an expression's class name matches
`Max` or `Min`.

## Callsite And Override Review

- No existing callsites require a new argument or changed return shape.
- No public method signature was changed.
- No subclass override is forced to accept a new keyword or protocol.
- Existing `MCodePrinter._print_Function` remains the implementation used for
  bracket-call formatting and user-function handling.

## Producer/Consumer Shape

Input remains a SymPy expression. Output remains a string. The only observable
shape change is for `Max` and `Min`, where invalid parenthesis-call syntax is
replaced with Mathematica bracket-call syntax.

## Result

PASS. The V1 source change is public-API compatible.
