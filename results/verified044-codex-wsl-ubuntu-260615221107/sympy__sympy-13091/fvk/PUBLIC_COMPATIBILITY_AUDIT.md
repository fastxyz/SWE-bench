# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbols

- `Basic.__eq__(self, other)`
- `Basic.__ne__(self, other)`
- `Expr.__lt__(self, other)`
- `Expr.__le__(self, other)`
- `Expr.__gt__(self, other)`
- `Expr.__ge__(self, other)`
- `Number.__lt__`, `Number.__le__`, `Number.__gt__`, `Number.__ge__`
- `Float.__eq__`, `Float.__ne__`, and ordering methods
- `Rational.__eq__`, `Rational.__ne__`, and ordering methods
- `Integer.__ne__` and ordering methods
- `Infinity.__eq__`, `Infinity.__ne__`, and ordering methods
- `NegativeInfinity.__eq__`, `NegativeInfinity.__ne__`, and ordering methods
- `NaN.__eq__`, `NaN.__ne__`
- `NumberSymbol.__eq__`, `NumberSymbol.__ne__`, and ordering methods

## Signature compatibility

All changed methods keep the same `(self, other)` signature. No new keyword arguments, positional parameters, return containers, storage formats, or public call protocols were introduced.

## Override/callsite compatibility

The patch changes return-category behavior only in unsupported comparison branches. It does not add virtual dispatch calls, alter call shapes, or require subclass overrides to accept new parameters.

## Return-category compatibility

- Intended change: unsupported comparisons return `NotImplemented`.
- Preserved: known numeric equality and ordering still return definite booleans or existing invalid-comparison errors.
- V2 correction: singleton equality no longer sympifies `other`, avoiding V1's unintended equality widening for sympifiable non-identical values.

## Tests

No test files were modified. Any recommendation to remove or relax tests would be conditioned on machine-checking; no such removal is recommended here.
