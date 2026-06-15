# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public symbol

- `django.db.models.enums.ChoicesMeta.__new__()`

## Compatibility result

| Surface | Audit | Result |
| --- | --- | --- |
| Signature | V1 does not change `ChoicesMeta.__new__(metacls, classname, bases, classdict)`. | Compatible |
| Return type | V1 still returns `enum.unique(cls)`. | Compatible |
| Exports | `Choices`, `IntegerChoices`, and `TextChoices` remain the exported names in `__all__`. | Compatible |
| Enum member data | V1 assigns `do_not_call_in_templates` after `EnumMeta` creates the class, so it is not inserted into `classdict._member_names`. | Compatible |
| Template callable behavior | V1 uses the existing `do_not_call_in_templates` branch in `Variable._resolve_lookup()` and does not change the resolver. | Compatible |
| Existing choices APIs | `choices`, `labels`, `values`, `names`, `label`, containment, and `__str__` logic are not edited. | Compatible |

## Public callsite scan

The public source references found for the choices classes are class
definitions, migrations serialization, and tests of enum behavior. None call
`ChoicesMeta.__new__()` directly or depend on absence of arbitrary class
attributes. No public override or virtual dispatch shape is affected.

## Verdict

No compatibility-blocking callsite, subclass override, producer/consumer shape,
or signature issue was found.
