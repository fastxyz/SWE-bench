# Baseline Notes

## Root cause

`CombinedExpression` inferred its `output_field` using the generic
`BaseExpression._resolve_output_field()` behavior, which returns the common
source field type when both operands have the same type. For
`F('end') - F('start')`, both operands are `DateTimeField`, so the subtraction
expression incorrectly resolved as `DateTimeField`.

The SQL compilation path already recognized same-type temporal subtraction and
compiled it through `TemporalSubtraction`, whose output is `DurationField`.
That specialization happened too late for nested expression type resolution.
When the temporal subtraction was added to a `DurationField` value, the outer
expression saw `DateTimeField + DurationField` and raised the mixed-types
`FieldError`.

## Changed files

`repo/django/db/models/expressions.py`

- Added a `CombinedExpression._resolve_output_field()` override for subtraction
  of matching temporal fields (`DateField`, `DateTimeField`, and `TimeField`).
- The override returns `DurationField` for those temporal subtraction cases and
  delegates all other combinations to the existing generic inference logic.
- This keeps the existing backend-specific SQL generation in
  `CombinedExpression.as_sql()` and `TemporalSubtraction.as_sql()` unchanged.

## Assumptions and alternatives

- Assumed the intended behavior applies to same-type temporal subtraction,
  matching the existing SQL specialization condition.
- Rejected broad changes to all duration arithmetic inference because the issue
  is specifically about temporal subtraction and the current backend SQL paths
  distinguish duration arithmetic in ways that depend on database features.
- Considered rewriting `resolve_expression()` to return a `TemporalSubtraction`
  instance earlier, but a targeted `output_field` override fixes the reported
  type-resolution failure while leaving expression resolution and SQL rendering
  otherwise unchanged.
- Did not add or modify tests, and did not run tests or execute code, per the
  benchmark instructions.
