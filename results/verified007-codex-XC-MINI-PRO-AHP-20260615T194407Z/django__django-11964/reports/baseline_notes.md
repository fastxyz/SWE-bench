# Baseline Notes

## Root cause

`TextChoices` and `IntegerChoices` members are enum members that also carry a concrete value such as `str` or `int`. When a model is created with a field value like `MyChoice.FIRST_CHOICE`, normal model initialization stores that member directly in the instance `__dict__`. A later fetch from the database stores the primitive database value instead.

The immediate user-visible mismatch is caused by `Choices` inheriting enum's default string conversion, so `str(MyChoice.FIRST_CHOICE)` renders the enum member name rather than the underlying value. This makes freshly created instances behave differently from retrieved instances even though the enum member's `.value` is the correct field value.

## Changed files

`repo/django/db/models/enums.py`

- Added `Choices.__str__()` to return `str(self.value)`.
- This keeps enum member identity, labels, choices, and `repr()` behavior unchanged while making string conversion match the primitive value stored after a database round trip.

## Assumptions and rejected alternatives

- I assumed the desired fix is for enum choice members to stringify as their concrete field values. The public issue demonstrates the failure through `str(field_value)` and notes that external API output can receive `MyChoice.FIRST_CHOICE` instead of `first`.
- I considered coercing model field assignments or model initialization values to primitive values. I rejected that because normal concrete field descriptors do not coerce arbitrary assignment, and introducing assignment-time conversion would be a much broader ORM behavior change.
- I considered changing `CharField` and `IntegerField` preparation methods. I rejected that because database preparation already stores the primitive value; the mismatch happens on the in-memory instance before it is refreshed or reloaded.
- I did not run tests or project code, per the benchmark instruction that this session has no execution environment.
