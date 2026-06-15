# Baseline Notes

## Root cause

`construct_instance()` skipped assigning any model field with a default when the
field's widget reported that its value was omitted from submitted data. That
preserved model defaults for ordinary optional omitted fields, but it also
ignored values deliberately placed in `form.cleaned_data` by `clean_<field>()`
or `clean()`.

The problematic case is a ModelForm field that is present on the form but absent
from the request payload because its value is derived during form cleaning. If
the model field has a default, the previous default-preservation branch ran
before `save_form_data()`, so the derived cleaned value never reached the model
instance.

## Changed files

- `repo/django/forms/models.py`: refined the omitted-default skip in
  `construct_instance()` so it only preserves the model default when the omitted
  form field's cleaned value is still one of the form field's empty values. A
  non-empty value supplied through `cleaned_data` is now assigned to the model
  instance through the existing `save_form_data()` path.

- `reports/baseline_notes.md`: added this explanation of the root cause, the
  source change, and the assumptions considered.

## Assumptions and alternatives

- I assumed the existing behavior that an omitted optional field with an empty
  cleaned value should continue to use the model default. Existing source tests
  in `tests/model_forms/tests.py` document that behavior for omitted text,
  date/time, and file fields.

- I treated checkbox and multi-select widgets as already handled by their
  `value_omitted_from_data()` implementations. They report unchecked or
  unselected submissions as not omitted, so the new empty-value check does not
  alter that path.

- I considered removing the omitted-default skip entirely, but rejected that
  because it would make ordinary missing optional fields overwrite model
  defaults with empty values.

- I considered comparing cleaned values to a second call of the form field's
  cleaning logic for the raw widget value, but rejected that because it would
  rerun validators and custom cleaning side effects. Checking the field's
  `empty_values` is narrower and matches the existing default-preservation
  intent.

- I did not run tests or project code, as requested by the benchmark
  instructions.
