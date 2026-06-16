# Baseline Notes

## Root cause

`BaseForm._clean_fields()` fetched submitted data and disabled-field initial
values directly from the form and fields instead of using the `BoundField`
object for each field. For callable initial values, this could evaluate the
callable separately from `BoundField.initial`, producing different values for
the same field during cleaning and rendering.

`BaseForm.changed_data` also duplicated per-field data and initial handling in
the form class. This left the form with a separate code path for determining
whether a bound field changed, including special handling for
`show_hidden_initial`.

## Changed files

`repo/django/forms/forms.py`

- Added `BaseForm._bound_items()` to yield `(name, BoundField)` pairs using the
  existing bound-field cache.
- Updated `_clean_fields()` to read each field's data through the corresponding
  `BoundField`: disabled fields use `bf.initial`, and other fields use
  `bf.data`.
- Updated `FileField` cleaning to pass `bf.initial` so callable initial values
  are evaluated consistently with the bound field.
- Simplified `changed_data` to delegate per-field change detection to
  `BoundField._has_changed()`.

`repo/django/forms/boundfield.py`

- Imported `ValidationError` for hidden-initial parsing.
- Added `BoundField._has_changed()` with the existing `changed_data` logic:
  compare `self.data` against `self.initial`, or against the parsed hidden
  initial value when `show_hidden_initial` is enabled.

## Assumptions and alternatives considered

- I assumed `BoundField.initial` is the canonical place to cache callable
  initial values, because it is already a `cached_property` and is used when
  rendering field values.
- I kept the method private as `_has_changed()` because the surrounding logic is
  internal form machinery and mirrors `BaseForm.has_changed()` naming.
- I considered only changing the disabled-field branch in `_clean_fields()`, but
  rejected that because the issue explicitly asks for both `_clean_fields()` and
  `changed_data` to access values through `BoundField` to reduce duplicate code
  paths.
- I did not change tests or run code/tests, per the benchmark instructions.
