# Public Compatibility Audit

Changed public symbol: `UnitSystem._collect_factor_and_dimension`.

## Signature And Return Shape

The V1 fix does not change the method name, arguments, visibility, or return
type. Accepted additions still return `(factor, dimension)`.

## Call Sites

Known public call paths in source:

- `Quantity._collect_factor_and_dimension(expr, unit_system="SI")` delegates to
  `unit_system._collect_factor_and_dimension(expr)`.
- Internal units utilities and public tests call the method directly on `SI`.

No call site requires an update because the method signature and return shape
are unchanged.

## Error Behavior

For incompatible dimensions, `ValueError` remains the public error path. V1 only
prevents that error when the active dimension system reports equivalent
dependencies.

## Overrides And Subclasses

No public subclass override of `_collect_factor_and_dimension` was found in the
units package. The change is local to `UnitSystem`.
