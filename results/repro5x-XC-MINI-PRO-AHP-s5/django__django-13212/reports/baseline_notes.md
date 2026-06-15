# Baseline notes — django__django-13212

## Issue

> Make validators include the provided value in `ValidationError`.

It should be possible to override a built-in validator's error message and use a
`%(value)s` placeholder so the message can echo the offending input, e.g.
`Email “blah” in cell A1 is not a valid email address.` The `%(value)s`
placeholder already appears in the docs example for writing custom validators
(`docs/ref/validators.txt`), but the built-in validators in
`django/core/validators.py` did not actually pass `value` to `ValidationError`,
so the placeholder rendered nothing (or raised a `KeyError`) when used with a
built-in validator.

## Root cause

`ValidationError.__iter__` (`django/core/exceptions.py`) renders a message with
`message %= error.params` only when `error.params` is set. The built-in
validators raised `ValidationError(self.message, code=self.code)` **without**
`params`, so the raw value was never made available for interpolation. The one
exception was `BaseValidator` (and its subclasses `MaxValueValidator`,
`MinValueValidator`, `MinLengthValidator`, `MaxLengthValidator`), which already
built `params = {'limit_value': ..., 'show_value': ..., 'value': value}`. That is
why `MaxLengthValidator(..., message='"%(value)s" ...')` already worked
(`tests/validators/tests.py::test_max_length_validator_message`) while the other
validators did not.

The fix is to add `value` to the `params` of every `ValidationError` raised by
the remaining built-in validators.

## Files changed

### `django/core/validators.py`

Added `params={'value': value}` (or added the `'value'` key to an existing
`params` dict) to every `ValidationError` raised by the built-in validators that
were missing it:

- `RegexValidator.__call__` — covers `validate_integer`, `validate_slug`,
  `validate_unicode_slug`, `validate_comma_separated_integer_list`, and
  `int_list_validator()`, which are all `RegexValidator` instances.
- `URLValidator.__call__` — all five raise sites (non-string input, bad scheme,
  invalid IPv6 URL `urlsplit`, IPv6 netloc validation failure, and the
  >253-char netloc check). Each uses the full URL `value`.
- `EmailValidator.__call__` — all three raise sites.
- `validate_ipv4_address`, `validate_ipv6_address`, `validate_ipv46_address`.
- `DecimalValidator.__call__` — the `invalid`, `max_digits`,
  `max_decimal_places`, and `max_whole_digits` raise sites. For the `invalid`
  branch I also added `code='invalid'` (previously it had no code), making it
  consistent with the other three branches whose code matches their message key.
- `FileExtensionValidator.__call__` — added `'value': value` alongside the
  existing `extension`/`allowed_extensions` params.
- `ProhibitNullCharactersValidator.__call__`.

`BaseValidator.__call__` already included `'value': value`, so it was left
unchanged.

No other files required changes: model-field and form-field error messages
already define and pass their own `%(value)s` params, and the issue is scoped to
`django.core.validators`.

## Why this is safe

- `ValidationError` only interpolates `message %= params` when `params` is
  truthy, and dict-style `%` formatting ignores extra keys. Every built-in
  default message either has no placeholder or only uses placeholders that are
  still supplied, so rendering an unchanged default message with
  `{'value': value}` returns the message unchanged — no `KeyError`, no behavior
  change for default messages. Lazy (`gettext_lazy`/`ngettext_lazy`) messages
  support the `%` operator, so this works for translated messages too.
- A `value` that itself contains a `%` is only ever a substitution *value*, not
  part of the format string, so it is never re-interpreted.
- The existing data-driven test (`TestValidators.test_validators`) only asserts
  whether a `ValidationError` is raised (and the return value for valid input);
  it does not inspect `code`/`params`, so these additions do not disturb it.

## Assumptions and rejected alternatives

- **Scope = `django.core.validators` only.** The issue text and the linked docs
  example are about built-in validators. Model/form field messages already
  expose `value`, so I did not touch them.
- **Add `value` to *all* remaining validators, including `DecimalValidator`,
  `FileExtensionValidator`, and `ProhibitNullCharactersValidator`**, rather than
  only the string-oriented ones (Regex/Email/URL/IP). The issue asks for built-in
  validators generally, and adding the key is harmless where unused. For
  `FileExtensionValidator` `value` is the file object; its `str()` is the file
  name, which is the natural thing a `%(value)s` placeholder would show.
- **Adding `code='invalid'` to `DecimalValidator`'s `invalid` branch.** Rejected
  leaving it codeless; giving it a code matches the sibling branches and the
  `self.messages` key, and the test suite does not assert on the absence of a
  code here.
- **Using a richer param set (e.g. also `show_value`).** Rejected as
  unnecessary; the issue specifically requests `%(value)s`, and `BaseValidator`
  is the only validator with a meaningful cleaned/`show_value` distinction.
- **Updating the docs.** Left out to keep the change minimal and targeted; the
  docs already document the `%(value)s` convention for writing validators.
