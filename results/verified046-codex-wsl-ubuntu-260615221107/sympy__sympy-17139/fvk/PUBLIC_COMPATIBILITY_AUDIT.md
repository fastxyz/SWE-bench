# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbol

`repo/sympy/simplify/fu.py::_TR56`

- Signature: unchanged.
- Return category: unchanged; returns a SymPy expression.
- Public wrappers affected: `TR5`, `TR6`, `TR15`, `TR16`, `TR22`.
- Wrapper signatures: unchanged.
- Dispatch/override concerns: none; these are module-level functions, not
  virtual methods.

## Callsite Compatibility

The callsites in `fu.py` continue to pass the same arguments:

- `TR5`: `_TR56(rv, sin, cos, ...)`
- `TR6`: `_TR56(rv, cos, sin, ...)`
- `TR15`: `_TR56(ia, sin, cot, ...)`
- `TR16`: `_TR56(ia, cos, tan, ...)`
- `TR22`: `_TR56(rv, tan, sec, ...)` and `_TR56(rv, cot, csc, ...)`

V2 only makes `_TR56` decline rewrites when the exponent is outside the proven
domain. No caller needs adaptation.
