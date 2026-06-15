# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbol

`django.contrib.admin.utils.display_for_field(value, field, empty_value_display)`

## Signature Compatibility

No signature change. Existing public callers still pass `(value, field, empty_value_display)`.

## Public Callers Checked

* `django.contrib.admin.helpers.AdminReadonlyField.contents()` calls `display_for_field(value, f, self.empty_value_display)`.
* `django.contrib.admin.templatetags.admin_list.items_for_result()` calls `display_for_field(value, f, empty_value_display)`.

No caller protocol changes are required.

## Virtual Dispatch and Overrides

The fix calls `field.formfield().prepare_value(value)` only for instances of `models.JSONField`. `models.JSONField.formfield()` is public model-field behavior and accepts no required positional arguments. Subclasses that override `formfield()` remain respected because the call dispatches through the field instance.

## Subclass Coverage

`django.contrib.postgres.fields.JSONField` subclasses `django.db.models.JSONField` in this checkout, so it is covered by `isinstance(field, models.JSONField)`.

## Result Shape

`display_for_field()` continues to return a display value suitable for existing escaping/linebreak handling by admin callers. The behavioral change is limited to non-null JSONField values that previously reached generic string fallback.

## Verdict

No compatibility blocker found. V1 can stand unchanged.
