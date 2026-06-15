# Baseline Notes

## Root cause

`EnumSerializer` in `django/db/migrations/serializer.py` serialized enum members by
serializing `self.value.value` and generating a constructor call such as
`Status('Good')`. For enum values backed by lazy translations, this bakes the
currently resolved display value into the migration. If the active language later
changes, the constructor lookup is attempted with a translated value that is not a
member value of the enum class, causing `ValueError`.

The enum member name is the stable identifier in this case. A migration expression
using `Status['GOOD']` reconstructs the same member without depending on the
localized or otherwise mutable enum value.

## Files changed

`repo/django/db/migrations/serializer.py`

- Changed `EnumSerializer.serialize()` to emit enum member lookup by name:
  `module.EnumClass['MEMBER']`.
- Removed serialization of the enum member value and its imports because the value
  is no longer referenced by the generated migration expression.

## Assumptions and alternatives considered

- I treated this as applying to general Python `enum.Enum` serialization, not only
  translated string values, because using the member name avoids value instability
  for all enum values while preserving the represented member.
- I left `ChoicesSerializer` unchanged. `models.Choices` has a separate serializer
  registered before `enum.Enum`, and it intentionally serializes to the underlying
  value used by Django choices fields.
- I considered preserving imports required by the enum value serializer, but rejected
  that because the generated expression no longer refers to the value and those
  imports would be unused.
- I kept the existing module/class naming style (`enum_class.__module__` and
  `enum_class.__name__`) to avoid unrelated changes to migration serialization.

No tests or project code were run, per the benchmark instructions.
