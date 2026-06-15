# Public Compatibility Audit

## Changed Symbol

`django.db.models.fields.related.ForeignKey.formfield(self, *, using=None, **kwargs)`

## Compatibility Findings

| Area | Audit result |
| --- | --- |
| Signature | Unchanged. No positional or keyword API was added or removed. |
| Return type | Still delegates to `super().formfield()` and returns the resulting form field. |
| Queryset behavior | Preserved: the same related model default manager and `using` value are supplied. |
| `to_field_name` behavior | Preserved: the same remote field name is supplied. |
| Explicit kwargs | Preserved except for the generated default when no `empty_label` was supplied. Explicit `empty_label` continues to override. |
| Admin radio fields | Preserved: admin already passes `empty_label` explicitly for radio foreign keys, so the new defaulting rule does not overwrite it. |
| Custom widgets | Improved: explicit `RadioSelect` widget classes/instances/subclasses and `form_class.widget = RadioSelect` now receive the non-blank default. |
| Non-radio widgets | Preserved: default `Select` and other widgets keep existing `ModelChoiceField.empty_label` behavior. |

No public callsite or subclass override was found that requires a signature or
producer/consumer protocol update.
