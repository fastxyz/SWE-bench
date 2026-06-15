# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Symbols

No public method signature, constructor signature, return-shape protocol, or
virtual dispatch call was changed.

## Audited Symbols

`CombinedExpression._resolve_output_field()`

- Compatibility status: source-compatible addition/override on an existing
  expression class.
- Public callsites: Django accesses this through the existing `output_field`
  cached property; the call shape is unchanged.
- Subclass impact: `DurationExpression` and `TemporalSubtraction` continue to
  inherit from `CombinedExpression`. `TemporalSubtraction` already defines a
  class-level `output_field`, so the new resolver override does not alter its
  declared output.

`CombinedExpression.as_sql()`

- Compatibility status: unchanged.
- Backend-specific rendering paths are preserved.

## Test Files

No test files were modified.

## Verdict

No compatibility finding blocks keeping V1.
