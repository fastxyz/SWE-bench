# Baseline Notes

## Root cause

`django.forms.JSONField.prepare_value()` serializes Python values for form widget display with `json.dumps(value, cls=self.encoder)`. Python's default JSON serialization escapes non-ASCII characters, so values such as Chinese or Japanese text are rendered in admin form textareas as `\uXXXX` escape sequences even though the underlying JSON value contains readable Unicode text.

This path is used for form/admin display. It is separate from `django.db.models.JSONField.get_prep_value()` and validation, which continue to use the existing serialization behavior for database writes and compatibility.

## Changed files

`repo/django/forms/fields.py`

Changed `JSONField.prepare_value()` to call `json.dumps()` with `ensure_ascii=False`. This preserves non-ASCII characters when JSON values are prepared for display in forms, including Django admin, while still honoring any configured custom JSON encoder.

`reports/baseline_notes.md`

Added this required report describing the issue, fix, and assumptions.

## Assumptions and rejected alternatives

Assumed the issue is limited to display/editing in form widgets, as described in `benchmark/PROBLEM.md`, and not to database serialization. Based on that, I did not change `django.db.models.fields.json.JSONField.get_prep_value()` or `validate()`.

Considered changing all JSON serialization for `JSONField`, but rejected it because the issue discussion specifically separates admin display from database write/read behavior, and broadening the change would risk backend compatibility concerns that are outside the requested fix.

Considered changing `has_changed()` to use `ensure_ascii=False` too, but rejected it because that method compares normalized JSON strings for equality and does not affect what the admin displays.
