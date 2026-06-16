# Public Compatibility Audit

Status: no compatibility issue found that requires a source change beyond V1.

## Changed Symbol

`django.forms.JSONField.prepare_value(self, value)`

- Signature: unchanged.
- Branch structure: unchanged except for the `ensure_ascii` argument in the non-invalid serialization call.
- Invalid input behavior: unchanged.
- Custom encoder behavior: preserved through `cls=self.encoder`.
- Return value: still a display string/string-like value; intentional content change only for non-ASCII JSON text.

## Public Callers and Integrations

`django.forms.boundfield.BoundField.value()`

- Calls `field.prepare_value(data)` after optional `bound_data()`.
- Compatible; no signature or return protocol change.

`django.db.models.fields.json.JSONField.formfield()`

- Continues to construct `forms.JSONField` with `encoder` and `decoder`.
- Compatible; no callsite update required.

`django.contrib.postgres.forms.jsonb.JSONField`

- Subclasses `django.forms.JSONField` and does not override `prepare_value()`.
- Compatible; inherits the fixed display behavior.

`django.forms.widgets.Textarea`

- Receives the prepared value through normal widget context rendering.
- Compatible; no safe-string or template contract change.

## Storage/Database Frame

`django.db.models.fields.json.JSONField.get_prep_value()` and `validate()` are unchanged. The display repair does not alter database serialization behavior.
