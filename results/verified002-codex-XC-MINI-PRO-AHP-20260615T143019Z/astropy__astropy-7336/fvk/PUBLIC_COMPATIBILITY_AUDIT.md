# Public Compatibility Audit

Status: static audit; constructed, not machine-checked.

## Changed Public Symbol

`astropy.units.quantity_input` exposes `QuantityInput.as_decorator`, which
returns `QuantityInput.__call__.wrapper` for decorated functions.

## Compatibility Checks

- Signature: unchanged. V1 adds no parameters and removes none.
- Decorator call shape: unchanged for `@u.quantity_input` and
  `@u.quantity_input(...)`.
- Wrapped function signature preservation: unchanged; the existing `@wraps`
  call remains in place.
- Argument validation behavior: unchanged; all edits are after the wrapped
  function returns.
- Return behavior for no annotation: unchanged.
- Return behavior for non-`None` unit annotations: preserved by the
  `return_annotation is not None` guard plus the existing `.to(...)` branch.
- Constructor use: improved for `-> None`, which is the reported public issue.

## Result

No public callsite, subclass override, or dispatch-shape update is required for
V1. The only behavioral change is the intended one: no-return annotations no
longer request unit conversion.
