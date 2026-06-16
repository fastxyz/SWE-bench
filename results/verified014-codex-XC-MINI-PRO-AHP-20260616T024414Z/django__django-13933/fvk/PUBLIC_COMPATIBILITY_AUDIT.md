# Public Compatibility Audit

Status: constructed from static source inspection, not machine-checked.

## Changed symbol

`django.forms.models.ModelChoiceField`

## Compatibility checks

| Check | Result |
| --- | --- |
| Constructor signature | Unchanged. |
| `to_python(self, value)` signature | Unchanged. |
| Successful return value | Unchanged: `None` for empty values, model instance for valid values. |
| Error code | Unchanged: invalid choices still use `invalid_choice`. |
| Error message key | Unchanged: `invalid_choice`. |
| Error params | Intentionally changed: invalid choices now include `{'value': value}`. |
| Public subclasses/overrides | Static search found subclasses overriding `label_from_instance()` but no public override of `to_python()` affected by a new call signature. |
| Public callsites | Static search found callsites instantiate `ModelChoiceField` normally; no caller depends on a changed signature. |

## Compatibility risk

Supplying params means a custom `invalid_choice` message with a literal percent
sign must use normal Django/Python percent escaping. This is already the
convention for `ChoiceField`, `TypedChoiceField`, `MultipleChoiceField`, and
`ModelMultipleChoiceField`; the public issue specifically requests that
`ModelChoiceField` join this convention.

Conclusion: no source compatibility issue blocks V1.

