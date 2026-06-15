# Intent Spec

Status: constructed, not machine-checked.

## Required behavior

1. `DecimalField.to_python(value)` returns `None` unchanged when `value is None`.
2. `DecimalField.to_python(value)` preserves the existing valid conversion behavior for integer, string, `Decimal`, tuple-supported, and other values accepted by `decimal.Decimal(value)`.
3. `DecimalField.to_python(value)` preserves the existing float-specific conversion through `self.context.create_decimal_from_float(value)`, including context precision behavior.
4. When `decimal.Decimal(value)` reports invalid decimal syntax with `decimal.InvalidOperation`, `DecimalField.to_python(value)` raises Django `ValidationError` with the existing `invalid` error message, `code='invalid'`, and `params={'value': value}`.
5. When `decimal.Decimal(value)` rejects an unsupported input type such as a dictionary with `TypeError`, `DecimalField.to_python(value)` raises the same Django `ValidationError`, not raw `TypeError`.
6. When `decimal.Decimal(value)` rejects a malformed conversion value with `ValueError`, `DecimalField.to_python(value)` raises the same Django `ValidationError`, not raw `ValueError`.
7. The public method signature, return type for valid inputs, and error payload for invalid inputs remain compatible with existing callers.

## Out of scope

- This FVK pass does not prove decimal arithmetic, rounding internals, or backend database adaptation. It treats Python's decimal conversion as an abstract operation with the exception classes observed by the field.
- This FVK pass does not prove total correctness or performance; `DecimalField.to_python()` has no loop or recursion in the audited code.
