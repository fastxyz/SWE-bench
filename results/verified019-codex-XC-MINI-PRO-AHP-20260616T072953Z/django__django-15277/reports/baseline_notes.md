# Baseline Notes

## Root cause

`Value._resolve_output_field()` returns `fields.CharField()` for string
values. That `CharField` has no `max_length`, which is valid for this
expression output-field use case, but `CharField.__init__()` unconditionally
added `validators.MaxLengthValidator(self.max_length)`. The resulting validator
was constructed with `None` as its limit, so validation paths such as
`clean()` could raise a `TypeError` when comparing a string length to `None`.
It was also unnecessary work for expression output fields where no maximum
length exists.

## Files changed

`repo/django/db/models/fields/__init__.py`

Changed `CharField.__init__()` to append `MaxLengthValidator` only when
`self.max_length is not None`. This mirrors the existing `BinaryField`
constructor behavior and keeps the normal validator for model
`CharField(max_length=...)` instances while avoiding an invalid validator for
unbounded `CharField()` instances.

## Assumptions and alternatives considered

I assumed that `CharField(max_length=None)` remains invalid for concrete model
fields through the existing system check, but can still be a legitimate
internal output field for expressions such as `Value('test')`.

I considered changing `Value._resolve_output_field()` to return a different
field type or to pass a calculated length, but rejected that because the issue
is the field constructor creating an invalid validator for any unbounded
`CharField()`, not just for `Value`.

I considered altering `MaxLengthValidator` to tolerate `None`, but rejected
that because validators should receive meaningful limit values. Skipping the
validator when no maximum exists is narrower and matches existing field
precedent.
