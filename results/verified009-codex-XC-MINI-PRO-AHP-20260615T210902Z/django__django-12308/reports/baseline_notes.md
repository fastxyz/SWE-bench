# Baseline Notes

## Root cause

Readonly admin fields are rendered through `django.contrib.admin.utils.display_for_field()`. That helper had special formatting for booleans, dates, numbers, and files, but not for `models.JSONField`. JSON values therefore fell through to `display_for_value()`, whose fallback is `str(value)`. For dictionaries this produces Python representation such as `{'foo': 'bar'}` instead of JSON text such as `{"foo": "bar"}`.

## Files changed

* `repo/django/contrib/admin/utils.py`
  * Added a `models.JSONField` branch to `display_for_field()`.
  * The branch delegates to `field.formfield().prepare_value(value)` so readonly admin display uses the same JSON serialization path as the form field, including custom encoders and `InvalidJSONInput` preservation.

## Assumptions and alternatives

* I treated the built-in `django.db.models.JSONField` as the correct type check because this checkout already exposes it and `django.contrib.postgres.fields.JSONField` subclasses it. This avoids checking a brittle internal type string and avoids direct coupling from admin to `contrib.postgres`.
* I left the existing `None` handling before the JSONField branch. In this admin helper, `None` generally means the model field is empty and should use `empty_value_display`; the reported problem concerns non-null JSON values being rendered with Python `repr`.
* I rejected calling `json.dumps()` directly in admin because it would duplicate serialization details and would not preserve `forms.InvalidJSONInput` behavior.
* I did not run tests or project code because the benchmark instructions explicitly forbid execution in this session.
