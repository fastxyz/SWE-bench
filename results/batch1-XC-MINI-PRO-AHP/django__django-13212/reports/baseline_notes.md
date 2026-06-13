# Baseline notes — django__django-13212

## Issue
"Make validators include the provided value in `ValidationError`."

It should be possible to write a custom validator error `message` that embeds the
value that failed validation, e.g. `“blah” is not a valid email address.`, by using
the `%(value)s` placeholder. The docs already advertise this placeholder for
user-written validators (`docs/ref/validators.txt`, the `validate_even` example),
but the **built-in** validators in `django.core.validators` did not pass the value
into the raised `ValidationError`, so `%(value)s` could not be used with them.

## Root cause
`ValidationError` only substitutes placeholders when it has a `params` dict:
in `django/core/exceptions.py::ValidationError.__iter__`, the message is rendered
as `message %= error.params` and this only runs `if error.params`.

`BaseValidator` (and therefore `MaxValueValidator`, `MinValueValidator`,
`MinLengthValidator`, `MaxLengthValidator`) already passed
`params={'limit_value': ..., 'show_value': ..., 'value': value}`, which is why the
existing `test_max_length_validator_message` test works with `%(value)s`.

The remaining built-in validators raised `ValidationError(self.message, code=...)`
with **no** `params`, so the value was never available for interpolation. The fix
is to add `params={'value': value}` to those raises.

## Files changed

### `django/core/validators.py`
Added `params={'value': value}` to every `ValidationError` raised by validators that
previously supplied no params:

- `RegexValidator.__call__` (covers all `RegexValidator` instances and subclasses —
  `validate_slug`, `validate_unicode_slug`, `integer_validator`/`validate_integer`,
  `int_list_validator`/`validate_comma_separated_integer_list`, and the
  `django.contrib.auth` `ASCIIUsernameValidator` / `UnicodeUsernameValidator`, which
  inherit this method unchanged).
- `URLValidator.__call__` — all five direct raises (non-string value, bad scheme,
  `urlsplit` `ValueError`, IPv6 netloc failure, and the >253-char host check). The
  two `super().__call__(...)` calls inherit the new params from `RegexValidator`; the
  re-raises (`raise e` / bare `raise`) propagate the original value. The original
  input value is reported in every case except the rare genuine-IDN path where
  `super().__call__(url)` runs against the punycode-normalized URL — an acceptable
  edge case left minimal.
- `EmailValidator.__call__` — all three direct raises.
- `validate_ipv4_address`, `validate_ipv6_address`, `validate_ipv46_address`.
- `ProhibitNullCharactersValidator.__call__`.

`BaseValidator.__call__` already includes `value` in params and was left as-is.

### `docs/ref/validators.txt`
Added a short note (with a `.. versionchanged:: 3.2`) under "Built-in validators"
explaining that each built-in validator now passes the value as `params['value']`,
so a custom `message` may use the `%(value)s` placeholder, with an `EmailValidator`
example.

## Why this is safe (no behavior change for default messages)
`ValidationError.__iter__` renders `message %= params` only when `params` is truthy.
Adding `params={'value': value}` now triggers that interpolation, but:
- The default messages contain no `%`-format specifiers, and Python's `%` with a
  **mapping** argument tolerates unused keys (`'Enter a valid value.' % {'value': x}`
  returns the string unchanged and never raises "not all arguments converted",
  because `params` is always a dict, never a bare value).
- The lazy (`gettext_lazy` / `ngettext_lazy`) messages already support `%`
  interpolation with a params mapping — this is the exact mechanism `BaseValidator`
  has always relied on.
- A `%` inside the validated `value` is not re-interpreted, since it is the
  substituted argument rather than part of the format template.

So rendered output is identical for the default messages, while custom messages can
now use `%(value)s`.

## Scope decisions / alternatives considered and rejected

- **`DecimalValidator` and `FileExtensionValidator` were intentionally left
  unchanged.** They already raise with their own contextual params (`max`, and
  `extension` / `allowed_extensions` respectively). The issue targets validators that
  previously exposed no params at all; adding `value` there is out of scope and would
  broaden the change without need. (`DecimalValidator`'s `value` is the `Decimal`
  itself and is implicit in those messages.)
- **Normalizing the IDN edge case in `URLValidator`** (wrapping
  `super().__call__(url)` to always report the original `value`) was rejected as
  unnecessarily invasive. For all non-IDN inputs the reconstructed URL equals the
  original, so the value is already correct; only true IDN inputs differ, and the
  normalized form is still informative.
- **Touching `django/forms` / model fields** was rejected: those layers consume these
  validators (or raise their own field-specific errors) and are unaffected by the
  issue, which is explicitly about `django.core.validators`.
