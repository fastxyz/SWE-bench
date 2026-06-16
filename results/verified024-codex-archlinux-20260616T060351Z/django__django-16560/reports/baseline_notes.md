## Root cause

`BaseConstraint` and its concrete subclasses exposed `violation_error_message`
but had no corresponding `violation_error_code` constructor argument or stored
attribute. The validation paths that raise constraint-specific
`ValidationError` instances therefore always created errors without a custom
code, even when callers could already customize the message.

## Files changed

`repo/django/db/models/constraints.py`

- Added `violation_error_code` to `BaseConstraint` and propagated it through
  `deconstruct()` and `clone()`, so migrations and cloned constraints preserve
  the value.
- Added the argument to `CheckConstraint` and `UniqueConstraint`, included it in
  equality and `repr()` output, and passed it to `ValidationError` in validation
  paths that use the constraint violation message.
- Left the plain field-based `UniqueConstraint` path without a condition on the
  existing `unique_error_message()` behavior for backward compatibility, matching
  the current special case for `violation_error_message`.

`repo/django/contrib/postgres/constraints.py`

- Added `violation_error_code` to `ExclusionConstraint`, passed it to
  `BaseConstraint`, included it in equality and `repr()` output, and applied it
  to the `ValidationError` instances raised by exclusion constraint validation.

## Assumptions and alternatives

- I treated the requested parameter as `violation_error_code`, based on the
  public hint and the existing `violation_error_message` naming.
- I assumed the code should apply wherever the constraint's own violation
  message is used. I rejected changing the legacy field-only
  `UniqueConstraint` branch because that branch intentionally uses
  `unique_error_message()` instead of `violation_error_message`.
- I kept the deprecated positional-argument compatibility in `BaseConstraint`
  aligned with the new argument, while preserving the existing deprecation
  warning behavior.
- I did not run tests or project code because the task explicitly forbids code
  execution in this session.
