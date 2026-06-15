# Baseline notes — django__django-13212

## Issue

> Make validators include the provided value in ValidationError

It is sometimes desirable to include the offending value in a custom error
message, e.g. `Email "blah" is not a valid email address.`. Django already
documents a `%(value)s` placeholder in the *Writing validators* section
(`docs/ref/validators.txt`), where a custom validator passes
`params={'value': value}` to `ValidationError`. However, Django's **built-in**
validators did not pass the value through, so a user who overrides a built-in
validator's `message` with one containing `%(value)s` would get a
`KeyError`/missing-substitution rather than the offending value. The request is
to make the built-in validators provide `value` so the `%(value)s` placeholder
is usable in overridden messages.

## Root cause

Most built-in validators in `django/core/validators.py` raised
`ValidationError(self.message, code=self.code)` **without** a `params`
dictionary. Because `ValidationError` only performs `%`-substitution against the
`params` mapping, there was no way for a user-supplied `message` to reference the
value being validated. `BaseValidator` (and therefore `MinValueValidator`,
`MaxValueValidator`, `MinLengthValidator`, `MaxLengthValidator`) was the only
group that already included `'value'` in its params (see line ~341,
`params = {'limit_value': ..., 'show_value': cleaned, 'value': value}`), which is
why the existing `test_max_length_validator_message` test could already use
`%(value)s`.

## Change

Single source file changed: `django/core/validators.py`.

For every built-in validator that previously raised `ValidationError` with **no**
params, I added `params={'value': value}` so the validated value is available for
message interpolation. Specifically:

- **`RegexValidator.__call__`** — the lone `raise` when the regex match fails.
  This is the base class for `URLValidator`, `validate_slug`,
  `validate_unicode_slug`, `validate_integer`/`integer_validator`,
  `int_list_validator`/`validate_comma_separated_integer_list`, so all of those
  inherit the new behavior.
- **`URLValidator.__call__`** — all five explicit `raise` sites (non-string
  input, bad scheme, `urlsplit` `ValueError`, bad IPv6 host, and the
  `netloc > 253` length check). The two `super().__call__(...)` calls now also
  carry `value` because `RegexValidator` does.
- **`EmailValidator.__call__`** — the three `raise` sites (empty/`@`-less value,
  bad user part, bad domain part).
- **`validate_ipv4_address`**, **`validate_ipv6_address`**,
  **`validate_ipv46_address`** — the standalone IP validators used by
  `GenericIPAddressField`.
- **`ProhibitNullCharactersValidator.__call__`** — the null-character check.

`value` is in scope at every edited site (each is inside a function/`__call__`
whose first non-`self` argument is `value`), so no other change is required. The
message strings themselves are intentionally left unchanged: the default English
messages don't reference `%(value)s`, and supplying an *extra*, unused key in
`params` is harmless. The benefit is purely additive — a user who overrides
`message` can now reference `%(value)s`.

## Deliberately not changed

- **`BaseValidator`** and its subclasses already include `'value'` in `params`;
  no change needed.
- **`DecimalValidator`** and **`FileExtensionValidator`** already raise with their
  own contextually meaningful params (`max`, `extension`,
  `allowed_extensions`). Their messages are not customizable through a simple
  `message` constructor argument the way the issue's `%(value)s` use case
  assumes, and their `value` is a `Decimal`/uploaded-file object rather than the
  user-facing string the issue is about. Adding `value` there would risk changing
  the existing `params` contract for those validators without serving the
  reported use case, so they were left as-is to keep the change minimal.

## Assumptions / alternatives considered

- **Assumption:** "include the provided value" means populating the
  `ValidationError` `params` with the key `value`, matching the existing
  `%(value)s` example in `docs/ref/validators.txt` and the
  `BaseValidator`/`MaxLengthValidator` precedent. This is the only interpretation
  consistent with how `ValidationError` interpolation works.
- **Alternative rejected — changing the default messages to show the value.**
  The issue asks for the value to be *available* for custom messages, not for the
  built-in English messages to change. Changing defaults would alter existing
  output and break a large number of existing tests/translations, so it was
  rejected.
- **Edge case — `URLValidator`'s IDN retry path.** When the trivial regex fails,
  the domain is punycode-encoded and re-validated via `super().__call__(url)`.
  If that re-validation fails, the propagated `ValidationError` carries the
  punycode-transformed URL as `value` rather than the original input. All other
  (and far more common) URL failure paths report the original `value`. I left
  this as-is rather than adding wrapping/re-raising logic, because the path is
  narrow and the change would add complexity beyond the minimal fix; the
  transformed value is still a reasonable representation of what was validated.
