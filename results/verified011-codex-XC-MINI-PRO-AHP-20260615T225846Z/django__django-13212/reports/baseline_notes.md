# Baseline Notes

## Root cause

Several built-in validators raised `ValidationError` with a custom message and
code but without a `params` dictionary containing the rejected input. Because
`ValidationError.__iter__()` interpolates message placeholders only from
`error.params`, user-supplied messages such as `"%(value)s is not valid"` could
not refer to the submitted value for many built-in validators.

`BaseValidator` already included `value` in its params, which is why
`MaxValueValidator`, `MinValueValidator`, `MaxLengthValidator`, and
`MinLengthValidator` already supported this pattern. Other validators in
`django.core.validators`, plus `KeysValidator` in `django.contrib.postgres`,
had direct `ValidationError` raises that omitted the value.

## Changed files

### `repo/django/core/validators.py`

Added `params={'value': value}` to direct validation failures in:

- `RegexValidator`, which also covers `validate_integer`,
  `validate_slug`, `validate_unicode_slug`,
  `validate_comma_separated_integer_list`, and validators produced by
  `int_list_validator()`.
- `URLValidator`, including non-string input, invalid schemes, parse failures,
  failed punycode fallback, invalid IPv6 literals, and overlong host names.
  The punycode retry now re-raises with the original submitted URL in
  `value`, not the transformed ASCII URL.
- `EmailValidator`, preserving the full submitted email value even when the
  invalid part is only the user or domain portion.
- `validate_ipv4_address`, `validate_ipv6_address`, and
  `validate_ipv46_address`.
- `DecimalValidator`, while preserving existing `max` params and existing
  error codes.
- `FileExtensionValidator`, while preserving `extension` and
  `allowed_extensions`.
- `ProhibitNullCharactersValidator`.

### `repo/django/contrib/postgres/validators.py`

Added `value` to `KeysValidator` params for both missing-key and extra-key
errors while preserving the existing `keys` param. The other validators in this
module inherit from `BaseValidator`, so they already receive `value`.

## Assumptions and alternatives considered

I treated "built-in validators" as Django's validator classes and functions,
not field-level validation errors from forms or model fields. Form and model
field errors have their own semantics and were outside the issue description.

I included `django.contrib.postgres.validators.KeysValidator` because it is a
Django-provided validator with direct `ValidationError` raises. I did not make
broader changes in contrib forms, fields, or model code because those are not
documented as reusable validator callables in the same sense.

I passed the original submitted value rather than normalized or derived pieces
such as punycoded URLs, email domain parts, IP literal fragments, file
extensions, or key lists. Existing specialized placeholders remain available
for those derived values.

I did not modify tests and did not run tests or project code, per the task
constraints.
