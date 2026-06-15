# Baseline notes — django__django-13212

## Issue

> Make validators include the provided value in `ValidationError`.

Users want to customize a validator's error message and reference the value that
failed validation, e.g. `“blah” is not a valid email address.` The Django docs
already advertise a `%(value)s` placeholder for custom validators
(`docs/ref/validators.txt`, the `validate_even` example), but the **built-in**
validators in `django/core/validators.py` did not pass the value into the
`ValidationError`, so `%(value)s` could not be used when overriding their
messages.

## Root cause

`ValidationError` only substitutes placeholders into a message when it is given a
`params` dict — see `ValidationError.__iter__` in `django/core/exceptions.py`
(`message %= error.params`). Most built-in validators raised
`ValidationError(self.message, code=self.code)` **without** any `params`, so the
provided value was never available for interpolation. `BaseValidator` was the
only validator that already passed `{'value': value, ...}`.

The fix is to thread the provided value into the `params` of every
`ValidationError` raised by the built-in validators (`params={'value': value}`,
or merging `'value': value` into already-present params).

## Files changed

### `django/core/validators.py`
Added the provided value to the `params` of every raised `ValidationError`:

- `RegexValidator.__call__` — added `params={'value': value}`.
- `URLValidator.__call__` — added `params={'value': value}` to all five raises
  (non-string value, invalid scheme, `urlsplit` `ValueError`, IPv6-in-netloc
  failure, and the 253-char netloc length check). The two re-raises (`raise e`
  and bare `raise`) already propagate an error whose params were set by the
  underlying `RegexValidator`, so they need no change.
- `EmailValidator.__call__` — added `params={'value': value}` to all three
  raises (empty/`@`-less value, invalid user part, invalid domain part).
- `validate_ipv4_address`, `validate_ipv6_address`, `validate_ipv46_address` —
  added `params={'value': value}`.
- `DecimalValidator.__call__` — added `'value': value` to the three existing
  `params` dicts (`max_digits`, `max_decimal_places`, `max_whole_digits`) and,
  for the `invalid` case which previously passed neither `code` nor `params`,
  added `code='invalid'` and `params={'value': value}` to make it consistent
  with the other validators.
- `FileExtensionValidator.__call__` — added `'value': value` to its existing
  `params` dict (alongside `extension`/`allowed_extensions`).
- `ProhibitNullCharactersValidator.__call__` — added `params={'value': value}`.

`BaseValidator.__call__` (and its `Min/Max` subclasses) already included
`'value': value`, so it was left unchanged.

### `docs/releases/3.2.txt`
Added a short "Validators" release note documenting that built-in validators now
include the provided value in the raised `ValidationError`, enabling the
`%(value)s` placeholder in custom messages.

## Why this is safe for existing (unchanged) messages

`ValidationError` only applies `message %= params` when `params` is truthy.
Adding `params={'value': value}` to a default message that contains no
placeholders (e.g. `"Enter a valid email address."`) is a no-op: Python's `%`
formatting against a dict returns the string unchanged when it has no
`%(...)s` markers, and ignores unused dict keys. None of the default messages
touched here contain a literal `%`, so their rendered output is identical.

## Assumptions / alternatives considered

- **Scope limited to `django/core/validators.py`.** The issue and its linked PR
  target the built-in validators in this module. I did not modify form/model
  field `clean()` paths, since the request is specifically about the reusable
  built-in validators advertised in `docs/ref/validators.txt`.
- **Placeholder name `value`.** Chosen to match the documented example
  (`%(value)s` / `params={'value': value}`) in `docs/ref/validators.txt`, rather
  than inventing a new key.
- **Comprehensive vs. single-validator change.** I considered only updating the
  `EmailValidator` (the issue's concrete example), but the issue title and
  rationale ask for built-in validators generally, so I applied the same
  treatment uniformly to keep behavior consistent and predictable.
- **URLValidator IDN branch.** When the IDN fallback re-validates the
  punycode-encoded URL via `super().__call__(url)`, the value carried in params
  is that transformed `url` rather than the original input. This only differs for
  non-ASCII domains (ASCII input is unchanged by `punycode`), and matches the
  existing minimal structure of the method; I deliberately did not add extra
  wrapping to re-substitute the original value, to keep the change minimal.
- **`DecimalValidator` `invalid` raise.** I added `code='invalid'` there in
  addition to `params`. The previous call omitted `code`, which would have
  produced a `ValidationError` with `code=None`; supplying the explicit
  `'invalid'` code matches the validator's `messages` key and the convention used
  by the other branches, and is consistent with the value-in-params goal.
