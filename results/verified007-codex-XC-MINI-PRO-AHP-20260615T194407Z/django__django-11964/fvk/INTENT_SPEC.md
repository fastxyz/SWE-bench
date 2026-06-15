# Intent Spec

Status: constructed from public intent only; not machine-checked.

## Public Intent Obligations

1. For a `TextChoices` member used as a `CharField` value during model creation, the field value must stringify to the member's concrete string value.
   - Example obligation: `str(MyChoice.FIRST_CHOICE) == "first"` when the enum value is `"first"`.

2. A freshly created model instance and a database-retrieved model instance must expose the same string-rendered field value for the same choice.
   - Created instance storage may contain the enum member.
   - Retrieved instance storage may contain the primitive database value.
   - The observable `str(field_value)` must match in both cases.

3. The issue title includes `IntegerChoices`; the same obligation applies to `IntegerChoices` members used as `IntegerField` values.
   - For a member with concrete value `1`, string rendering must match the primitive value's string rendering.

4. The fix must preserve the documented enum choice API: `.choices`, `.labels`, `.values`, `.names`, `.label`, `.value`, enum lookup by name and value, and `repr()` behavior tested by the public in-repo enum tests.

5. The fix must avoid broad ORM assignment coercion unless public intent requires it. The public failure is `str(field_value)`, not a requirement that model `__dict__` storage be rewritten on assignment.

## Default-Domain Assumptions

- A valid choice member has a concrete value of the field-compatible type: `str` for `TextChoices`, `int` for `IntegerChoices`.
- Python/Django enum member identity and lookup semantics remain intact unless public intent states otherwise.
- This FVK pass proves partial correctness of the modeled observable; there are no loops or termination obligations in the changed method.
