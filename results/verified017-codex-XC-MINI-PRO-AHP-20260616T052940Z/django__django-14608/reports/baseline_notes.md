# Baseline Notes

## Root cause

Form errors already distinguish non-field errors by constructing their
`ErrorList` instances with `error_class='nonfield'`. Formset-level non-form
errors used the same `ErrorList` class but constructed it without an extra
class in `BaseFormSet.full_clean()`, both for the initially empty
`_non_form_errors` list and for the replacement list created from a
`ValidationError`. As a result, rendered formset non-form errors only had the
base `errorlist` CSS class and custom `ErrorList` implementations had no
signal that the errors came from the formset level.

## Changed files

`repo/django/forms/formsets.py`

Updated `BaseFormSet.full_clean()` so `_non_form_errors` is created with
`error_class='nonform'`. This covers empty/unbound formsets, management-form
errors appended to the existing list, and formset validation errors caught from
`clean()`, `validate_min`, and `validate_max`.

`repo/docs/topics/forms/formsets.txt`

Documented that `formset.non_form_errors` renders with the additional
`nonform` CSS class and added a small HTML example, matching the existing
documentation style for form non-field errors.

## Assumptions and alternatives considered

I assumed the intended behavior should mirror `Form.non_field_errors()`, which
uses the same `ErrorList` constructor hook with a different class name. I also
assumed all formset-level non-form error lists should carry the class, even
when empty, because custom `ErrorList` subclasses can inspect the constructor
argument before rendering.

I considered adding the class only when rendering non-empty validation errors,
but rejected that because it would leave management-form errors and empty
`non_form_errors()` results inconsistent. I also rejected changing
`ErrorList` itself because the issue is specific to formsets and existing form
behavior already has the correct call-site-specific class.
