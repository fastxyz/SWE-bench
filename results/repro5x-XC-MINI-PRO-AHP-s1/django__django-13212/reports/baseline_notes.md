# Baseline notes — django__django-13212

## Issue

> Make validators include the provided value in `ValidationError`.

It should be possible to override a built-in validator's error message and use a
`%(value)s` placeholder to render the invalid value (e.g. `Email "blah" is not a
valid email address.`). This placeholder name already appears in the docs example
for writing custom validators (`docs/ref/validators.txt`), but the built-in
validators did not supply `value` in the `ValidationError` `params`, so the
placeholder could not be used with them.

## Root cause

`ValidationError` renders its message lazily by doing `message %= self.params`
(see `django/core/exceptions.py:173-174`). A `%(value)s` placeholder is therefore
only substituted if the validator passes `params` containing a `value` key.

`BaseValidator` and its subclasses (`MaxValueValidator`, `MinValueValidator`,
`MinLengthValidator`, `MaxLengthValidator`) already included `'value': value` in
`params` (`django/core/validators.py:341`), which is why the pre-existing
`test_max_length_validator_message` test could use `%(value)s`.

The remaining built-in validators raised `ValidationError(self.message,
code=self.code)` (or the literal-message IP variants) **without any `params`**, so
there was no `value` available for a custom message to reference.

## Files changed

### `django/core/validators.py`

Added `params={'value': value}` to every `ValidationError` raised by the
validators that previously passed no `params`. All of these raises occur inside a
`__call__(self, value)` method or a module-level `validate_ipv*(value)` function,
so `value` is the in-scope value being validated:

- `RegexValidator.__call__` (covers all `RegexValidator`-based validators:
  `validate_slug`, `validate_unicode_slug`, `integer_validator` /
  `validate_integer`, `validate_comma_separated_integer_list`, and instances
  produced by `int_list_validator`).
- `URLValidator.__call__` — all five direct raises (non-string input, bad scheme,
  unsplittable URL, bad literal IPv6 host, and over-long netloc).
- `EmailValidator.__call__` — all three raises (empty/`@`-less, bad user part,
  bad domain part); `value` remains the original input even though `domain_part`
  is locally reassigned in the IDN branch.
- `validate_ipv4_address`, `validate_ipv6_address`, `validate_ipv46_address`.
- `ProhibitNullCharactersValidator.__call__`.

The ten `self.message`-based raises were identical strings, so they were updated
in a single `replace_all` edit; the three literal-message IP validators were
updated individually.

## Why this is safe (no impact on existing behavior)

- `ValidationError` only formats the message when `params` is truthy. None of the
  default validator messages contain a literal `%`, and formatting a string with
  no placeholders against a dict returns it unchanged
  (`"Enter a valid email address." % {'value': v}` -> same string). So default
  error text, `str()`/`repr()` of these errors, and the raise/no-raise behavior
  asserted by the existing `TEST_DATA` suite are all unchanged.
- The validator `__eq__` / `deconstruct` machinery does not consider `params`, so
  equality and migration-serialization tests are unaffected.
- `self.message` may be a lazy translation proxy; `lazy %= dict` is already used
  for the `BaseValidator` subclasses, so this path is well supported.

## Assumptions / alternatives considered

- **Scope = `django.core.validators` only.** The issue and the linked docs anchor
  refer to this module; per-field validators and `django.contrib.postgres`
  validators were left untouched.

- **`DecimalValidator` and `FileExtensionValidator` were intentionally left
  unchanged.** Unlike the validators above, these already pass a `params` dict
  with task-specific context (`max`, `extension`, `allowed_extensions`), so they
  already "provide values to `ValidationError`". Their messages describe a
  constraint rather than echo the value, and `FileExtensionValidator`'s value is a
  `File` object rather than the human-facing string the issue is about. Adding
  `value` there would be broader than the reported problem (which is about the
  validators that currently expose *no* params). This keeps the change minimal and
  targeted; it can be revisited if a `value` placeholder is later wanted for those
  two.

- **IDN edge case in `URLValidator`.** On the IDN retry path, `super().__call__(url)`
  is invoked with the punycode-encoded URL; if it fails, the `RegexValidator`
  error will carry the encoded `url` as `value` rather than the original input.
  The original value is preserved for the common (non-IDN) failures via the five
  direct raises and the re-raised `e`. Reworking the IDN branch to always report
  the original value would be a larger, riskier refactor unrelated to the reported
  need, so it was deliberately not changed.

- **Documentation / release notes.** The `%(value)s` placeholder is already
  documented for custom validators; no behavioral docs change is required for the
  fix itself, and the task asks for a minimal source change, so docs/release notes
  were not modified.
