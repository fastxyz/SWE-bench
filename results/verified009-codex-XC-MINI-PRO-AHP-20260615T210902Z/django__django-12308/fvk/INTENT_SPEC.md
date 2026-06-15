# Intent-Only Specification

Status: derived from public prompt, public hint, and in-repository source/tests before accepting V1 behavior as correct.

1. Readonly admin display for a JSONField must not render JSON object values with Python dictionary repr.
2. A JSONField value such as `{"foo": "bar"}` must display as valid JSON text, not `{'foo': 'bar'}`.
3. Admin must use JSONField form preparation rather than a direct `json.dumps()` call so `InvalidJSONInput` remains unchanged.
4. The implementation must avoid coupling `django.contrib.admin` to `django.contrib.postgres` and avoid brittle field type-name checks.
5. A subclass of `django.db.models.JSONField`, including the deprecated postgres JSONField in this checkout, must use the same display path.
6. Existing admin empty-value behavior for `None` must be preserved unless stronger public intent overrides it.
7. Public callers of `display_for_field(value, field, empty_value_display)` must continue to use the same function signature and return protocol.
