# FVK Findings

Status: constructed, not machine-checked.

## F-001: Resolved code bug - JSONField object values used Python repr

Input: `display_for_field({"foo": "bar"}, models.JSONField(), empty_value_display)`.

Observed before V1: the value had no JSONField branch and fell through to `display_for_value()`, whose fallback was `str(value)`, producing `{'foo': 'bar'}`.

Expected from intent: a JSONField readonly value should display as valid JSON text, e.g. `{"foo": "bar"}`.

Resolution: V1 adds a `models.JSONField` branch that calls `field.formfield().prepare_value(value)`. This discharges PO-1 and PO-2.

## F-002: Confirmed requirement - InvalidJSONInput must not be double-serialized

Input: `display_for_field(InvalidJSONInput("{bad"), models.JSONField(), empty_value_display)`.

Failure mode if admin called `json.dumps()` directly: the invalid input would be transformed instead of preserved.

Expected from intent and `forms.JSONField.prepare_value()`: return the invalid JSON string unchanged.

Resolution: V1 delegates to `prepare_value()` rather than calling `json.dumps()` in admin. This discharges PO-3.

## F-003: Confirmed requirement - subclass/type handling must not be brittle

Input: `display_for_field({"foo": "bar"}, django.contrib.postgres.fields.JSONField(), empty_value_display)`.

Failure modes rejected by public hint: coupling admin to `contrib.postgres` or checking the field type name.

Expected: the deprecated postgres JSONField should use the same JSON display path because it subclasses `django.db.models.JSONField` in this checkout.

Resolution: V1 uses `isinstance(field, models.JSONField)`. This discharges PO-4.

## F-004: Audited boundary - `None` remains an admin empty value

Input: `display_for_field(None, models.JSONField(null=True), empty_value_display)`.

Potential alternative considered: moving the JSONField branch before the `value is None` branch would display JSON `null`.

Expected from the existing public admin utility contract: `None` is handled by `empty_value_display`, except for choices and Boolean special handling that already precede the null branch.

Resolution: V1 leaves the JSONField branch after `value is None`. This discharges PO-5 and avoids an unrelated behavior change.

## F-005: Compatibility audit found no required source change

Changed public symbol: `display_for_field(value, field, empty_value_display)`.

Compatibility result: the signature, return shape, and callers remain unchanged. The new branch only changes the display result for non-null JSONField instances that previously reached the generic fallback.

Resolution: V1 stands unchanged. This discharges PO-6.

## Proof-derived findings from `/verify`

No blocking proof-derived findings were found. The constructed claims cover the full public intent slice: non-null JSON object display, invalid input preservation, subclass handling, `None` empty display behavior, and non-JSON fallback preservation.

The proof remains constructed, not machine-checked. Test removal is not recommended unless the emitted K commands are later run and return `#Top`.
