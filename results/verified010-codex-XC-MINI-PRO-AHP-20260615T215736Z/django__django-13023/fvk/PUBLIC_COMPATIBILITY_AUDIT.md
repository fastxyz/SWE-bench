# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed public symbol: `django.db.models.fields.DecimalField.to_python(self, value)`.

| Compatibility axis | Audit result | Finding |
| --- | --- | --- |
| Method signature | Unchanged. | None. |
| Valid input return values | Preserved for `None`, floats, and valid `decimal.Decimal(value)` inputs. | None. |
| Existing invalid syntax error payload | Preserved: same `self.error_messages['invalid']`, same `code='invalid'`, same `params={'value': value}`. | None. |
| Callers | Existing callers invoke `to_python(value)` without new arguments. `get_db_prep_save()` and `get_prep_value()` benefit from the same normalized error. | None. |
| Subclass/override dispatch | No new virtual call and no method signature change. No repo source subclass of model `DecimalField` was found in `repo/django`; form `DecimalField` is separate. | None. |
| Exception compatibility | Unsupported dict input changes from raw `TypeError` to `ValidationError`, which is the intended compatibility correction per the issue and base field contract. | Resolved finding F1. |
