# Baseline Notes

## Root cause

`DecimalField.to_python()` converted non-float values with `decimal.Decimal(value)` and only handled `decimal.InvalidOperation`. Unsupported input types, including dictionaries, are rejected by `decimal.Decimal()` with `TypeError` before decimal parsing reaches `InvalidOperation`. That leaked a raw `TypeError` from model field conversion instead of Django's field-specific `ValidationError`.

## Changed files

`repo/django/db/models/fields/__init__.py`

- Updated `DecimalField.to_python()` to catch `TypeError` and `ValueError` alongside `decimal.InvalidOperation` and raise the existing `ValidationError` with the existing message, code, and value params.
- Included `ValueError` because malformed conversion inputs can fail that way too, and sibling numeric model fields treat `TypeError` and `ValueError` as invalid user data during `to_python()` conversion.

## Assumptions and alternatives

- Assumed the intended behavior is that values which cannot be converted to a `Decimal` during model field cleaning should produce `ValidationError`, matching the base field contract and the behavior of integer and float model fields.
- Considered catching only `TypeError`, which would directly fix dictionaries. Rejected it because it leaves another conversion-failure path as a raw exception and is less consistent with adjacent numeric field implementations.
- Considered converting through `str(value)` like the form `DecimalField`. Rejected it because model fields currently pass acceptable Decimal constructor inputs through directly, including tuples that the decimal module supports, and this issue only requires normalizing conversion exceptions.
- Tests were not run because the benchmark instructions prohibit running tests or project code in this session.
