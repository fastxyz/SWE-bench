# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public symbol

`django.db.models.enums.Choices.__str__`

V1 adds this method to the base `Choices` class. It affects `TextChoices`, `IntegerChoices`, and custom concrete subclasses of `Choices`.

## Callsite and API compatibility

| Surface | Public evidence | Compatibility result |
| --- | --- | --- |
| `TextChoices` string conversion | The issue requires `str(MyChoice.FIRST_CHOICE) == "first"`. | Compatible and required. |
| `IntegerChoices` string conversion | The issue title names `IntegerChoices`; concrete values are documented through `.value`. | Compatible and required by family intent. |
| `.choices`, `.labels`, `.values`, `.names` | Public enum tests assert exact lists. | Unchanged; V1 only adds `__str__`. |
| `.label` and `.value` | Public enum tests assert these properties. | Unchanged. |
| `repr(member)` | Public enum tests assert enum-style `repr()`. | Unchanged; V1 does not define `__repr__`. |
| Enum lookup by name/value | Public enum tests assert `Suit(1)` and `YearInSchool("FR")`. | Unchanged. |
| Model field assignment and retrieval | Existing CharField tests show DB round trips already produce primitive-compatible values. | Unchanged; no descriptor or field-preparation API changes. |
| Custom `Choices` subclasses | Docs describe custom concrete data types for choices but do not specify legacy enum-name stringification. | V1 changes `str()` to concrete-value string uniformly. This is broader than the minimal issue example but aligned with the same concrete-value principle and avoids duplicate overrides in subclasses. |

## Compatibility Conclusion

No public callsite, override, or producer/consumer protocol requires the old enum-name `str()` output. The base-class placement is acceptable because it preserves existing enum metadata and extends the value-string rule uniformly to all concrete choice subclasses.
