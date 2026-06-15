# Baseline Notes

## Root cause

`AuthenticationForm` declares its `username` field before the active user model is
known for each form instance. During form initialization, it updates
`self.fields['username'].max_length` from the user model's `USERNAME_FIELD`, with
a fallback of `254`.

However, `forms.Field.__init__()` applies field-specific HTML attributes to the
widget when the field object is created. At that point, `AuthenticationForm`'s
`UsernameField` has no `max_length`, so `forms.CharField.widget_attrs()` cannot
add a `maxlength` attribute. Updating `max_length` later changes the field state
but leaves the widget attrs stale, so rendered login forms omit `maxlength`.

## Files changed

`repo/django/contrib/auth/forms.py`

Updated `AuthenticationForm.__init__()` to keep a local reference to the
`username` field, assign the dynamic `max_length`, and then refresh the widget
attributes by calling `username.widget_attrs(username.widget)`. This preserves
the existing dynamic max-length behavior while ensuring character fields render
the corresponding `maxlength` HTML attribute.

`reports/baseline_notes.md`

Added this required report describing the cause, implementation, assumptions,
and rejected alternatives.

## Assumptions and alternatives considered

I assumed the intended behavior is limited to reflecting the existing dynamic
`max_length` on the rendered widget. I did not add new validation behavior,
because the issue specifically describes the missing HTML `maxlength` attribute.

I considered directly setting `username.widget.attrs['maxlength']`, but rejected
that because subclasses may replace `username` with a non-character field.
Calling the field's own `widget_attrs()` keeps the behavior aligned with Django's
normal field initialization path and only adds attributes that the concrete field
considers appropriate.

I also considered moving the dynamic max-length selection into the class-level
field declaration, but rejected that because the value depends on the configured
user model and must continue to work for custom `AUTH_USER_MODEL` settings.
