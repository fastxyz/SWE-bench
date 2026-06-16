# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbol

`sympy.utilities.lambdify._recursive_to_string`

- Signature unchanged.
- Return type unchanged: still returns a source string.
- Supported input categories unchanged.
- Only observable source text for native singleton tuples changes, from invalid tuple-preserving source `(x)` to valid singleton tuple source `(x,)`.

## Public Callers and Protocols

`_EvaluatorPrinter.doprint` calls `_recursive_to_string(self._exprrepr, expr)` and then emits `return {str_expr}`. The V1 change is compatible with this protocol because `str_expr` remains a string and the corrected singleton tuple string is exactly the intended generated source.

`lambdastr` also calls `_recursive_to_string(lambdarepr, expr)` and wraps the result in a lambda body. The corrected singleton tuple fragment remains a valid Python expression and preserves the intended tuple shape.

The selected printer's `doprint` API is unchanged. V1 still calls it recursively for leaves and for non-container scalar objects exactly as before.

## Subclasses and Overrides

No public class method signature, virtual dispatch call shape, or subclass override contract is changed by V1. The edited helper is a module-level internal function.

## Compatibility Result

No compatibility finding blocks keeping V1. The only changed observable is the intended correction for native one-element tuple source.

