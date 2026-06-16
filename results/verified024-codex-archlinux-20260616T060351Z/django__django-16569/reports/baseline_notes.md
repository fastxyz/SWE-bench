# Baseline Notes

## Root cause

`BaseFormSet.empty_form` constructs a template form by calling
`add_fields(form, None)`. In `BaseFormSet.add_fields()`, the delete-field
condition compared `index < initial_form_count` whenever `can_delete` was true
and `can_delete_extra` was false. For an empty form, `index` is `None`, so this
comparison raised `TypeError: '<' not supported between instances of 'NoneType'
and 'int'`.

The ordering-field branch in the same method already treats `None` as the
special empty-form index and avoids comparing it to `initial_form_count`.

## Changed files

`repo/django/forms/formsets.py`

- Updated the delete-field condition in `BaseFormSet.add_fields()` so it only
  compares `index` to `initial_form_count` when `index is not None`.
- This preserves deletion fields for initial forms and for extra forms when
  `can_delete_extra` is true, while avoiding deletion fields on the empty
  template form when extra deletion is disabled.

## Assumptions and alternatives considered

- I assumed `index=None` continues to mean the empty template form because
  `empty_form`, `get_form_kwargs()`, and the ordering-field logic all document
  or implement that convention.
- I considered changing `empty_form` to pass a numeric placeholder index, but
  rejected that because `None` is the documented signal for a new empty form and
  other hooks may rely on it.
- I considered special-casing `empty_form` before calling `add_fields()`, but
  rejected that because the failing comparison is local to delete-field
  insertion and should be fixed where the invalid comparison happens.
- I did not modify tests per the task instructions.
