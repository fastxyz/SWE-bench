# Baseline Notes

## Root cause

`ModelChoiceField.to_python()` raised `ValidationError` with code
`invalid_choice` when the submitted value could not be converted or found in
the queryset, but it did not pass the rejected value in `params`. As a result,
custom `invalid_choice` messages could not interpolate `%(value)s`. The
default `ModelChoiceField` message also omitted the `%(value)s` placeholder,
unlike `ChoiceField` and `ModelMultipleChoiceField`.

## Changed files

`repo/django/forms/models.py`

- Updated `ModelChoiceField.default_error_messages['invalid_choice']` to include
  `%(value)s`, matching the behavior already used by other choice fields.
- Updated the `ValidationError` raised by `ModelChoiceField.to_python()` to pass
  `params={'value': value}` on invalid choices so overridden error messages can
  display the offending submitted value.

## Assumptions and alternatives considered

- I assumed the intended value is the same local `value` that failed lookup. For
  model instances of the correct model, this may be converted to the configured
  lookup key before the queryset lookup, which matches the value actually used
  for validation.
- I considered changing only the default message, but rejected that because
  custom `error_messages` with `%(value)s` would still fail to receive the
  parameter described in the issue.
- I considered changing only the raised `ValidationError` params, but rejected
  that because the issue also asks for the default invalid-choice message to
  expose the invalid value.
- I did not add or edit tests because the task forbids modifying test files, and
  I did not run tests or code because the task states this session has no
  execution environment.
