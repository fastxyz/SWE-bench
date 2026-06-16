# Baseline Notes

## Root cause

`ReadOnlyPasswordHashField` was display-only when rendered, but the field itself
was not disabled. During form cleaning, Django only ignores submitted values for
fields with `disabled=True`; otherwise the submitted value from
`value_from_datadict()` is cleaned and placed in `cleaned_data`.

`UserChangeForm.clean_password()` compensated for this in Django's built-in user
change form by returning the initial password hash, but custom forms using
`ReadOnlyPasswordHashField` without an equivalent `clean_password()` could still
accept a tampered submitted password value.

## Changed files

`repo/django/contrib/auth/forms.py`

Set `ReadOnlyPasswordHashField` to default `disabled=True` in its constructor.
This lets Django's existing form-cleaning path use the initial password value for
the field and ignore submitted data, even when a custom form doesn't define
`clean_password()`. The existing `required=False`, `bound_data()`, and
`has_changed()` behavior remains unchanged.

## Assumptions and alternatives considered

I assumed the intended fix is for the reusable field to own the tamper-resistant
behavior, because the issue specifically asks to set the disabled property on
`ReadOnlyPasswordHashField`.

I considered removing `UserChangeForm.clean_password()` because the disabled
field now makes it redundant for the built-in form. I left it in place to keep
the change minimal and avoid removing an existing method unnecessarily; it still
returns the same initial value and doesn't interfere with the new field-level
behavior.

I also considered changing the widget, but the root problem is not rendering.
The generic form cleaning path already has the desired behavior for disabled
fields, so no widget-specific logic is needed.
