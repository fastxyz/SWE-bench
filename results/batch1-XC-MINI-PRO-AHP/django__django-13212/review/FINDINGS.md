# Code review findings — django__django-13212 (V1 audit)

Issue: built-in validators should pass the value being validated into the raised
`ValidationError` so a custom `message` can use the `%(value)s` placeholder.

V1 added `params={'value': value}` to `RegexValidator`, `URLValidator` (5 direct
raises), `EmailValidator` (3 raises), `validate_ipv4_address`,
`validate_ipv6_address`, `validate_ipv46_address`, and
`ProhibitNullCharactersValidator`, plus a docs note. `BaseValidator` (and its
subclasses `Max/MinValueValidator`, `Max/MinLengthValidator`) already passed
`value`. `DecimalValidator` and `FileExtensionValidator` were left unchanged.

## F1 — Correctness against the issue (CONFIRMED correct)
The added `params={'value': value}` make `%(value)s` resolvable for the targeted
validators. `ValidationError.__iter__` renders `message %= error.params` only when
`params` is truthy (`django/core/exceptions.py:173-174`); a custom message such as
`'“%(value)s” is not a valid email address.'` now interpolates the input. The
mechanism is identical to the long-standing `BaseValidator` behavior exercised by
`tests/validators/tests.py::test_max_length_validator_message`. No correctness
defect found in the V1 edits themselves.

## F2 — Field message-replacement path (CONFIRMED safe, no regression)
`Field.run_validators` in both `django/forms/fields.py:138-139` and
`django/db/models/fields/__init__.py:606-607` does:
`if e.code in self.error_messages: e.message = self.error_messages[e.code]` while
**keeping** the validator's `params`. So a field can pair its own message with the
validator's (now populated) params, and that message gets `%`-formatted.

Risk = a field message whose code matches a modified validator's code and that
contains either (a) a placeholder other than `value`, or (b) a bare literal `%`.
Audited exhaustively:
- Codes raised by modified validators: `'invalid'` and
  `'null_characters_not_allowed'`.
- Base `forms.Field` defines only `'required'` (no `'invalid'`); base
  `models.Field` defines `'invalid_choice'`/`'null'`/`'blank'`/`'unique'`/
  `'unique_for_*'` — none of which are `'invalid'` or `'null_characters_not_allowed'`.
- Every field that attaches a modified validator (`EmailField`, `URLField`,
  `SlugField`, `GenericIPAddressField`, `CommaSeparatedIntegerField`,
  `CharField`+`RegexValidator`) either does **not** override `'invalid'` (so the
  validator's own placeholder-free message is used) or overrides it with a
  placeholder-free string (`URLField`: "Enter a valid URL.").
- The only `'invalid'` messages with non-`value` placeholders are
  `related.py:790` (`%(model)s/%(field)s/%(value)r`, ForeignKey) and the
  model scalar fields (`%(value)s` only) — none of which attach the modified
  validators; their `'invalid'` is raised by the field's own `to_python()`/
  `validate()` with its own params.
- No field defines a message for `'null_characters_not_allowed'`.
Conclusion: no regression in Django's own code.

## F3 — Default-message rendering is unchanged (CONFIRMED)
For the default, placeholder-free validator messages, switching `params` from
`None` to `{'value': value}` changes rendering from "skip `%`" to
`'…' % {'value': value}`, which returns the identical string (a mapping argument
tolerates unused keys and never raises "not all arguments converted"). Thus any
test asserting the rendered message string is unaffected; only `error.params`
changes from `None` to a dict.

## F4 — Lazy / ngettext messages with an extra param key (CONFIRMED safe)
`MinLengthValidator`/`MaxLengthValidator` already feed an `ngettext_lazy` message
keyed on `'limit_value'` a params dict that *also* contains `'show_value'` and
`'value'`. So providing extra keys (beyond the count key and the referenced
placeholders) to a lazy/`ngettext_lazy` message is already exercised and safe.
This directly licenses adding `'value'` to `DecimalValidator` (whose `max_*`
messages are `ngettext_lazy` keyed on `'max'`).

## F5 — Consumers of `ValidationError.params` (CONFIRMED safe)
Only two consumers exist: `core/exceptions.py` (guards with `if error.params:`)
and `contrib/postgres/utils.py::prefix_validation_error` which does
`error.params or {}` then `error.message % error_params` and merges
`{**error_params, **params}`. Both handle a dict gracefully; adding a `'value'`
key only enriches the merged params and never breaks the existing `%` render
(the inner message is placeholder-free for these validators). No consumer assumes
`params is None`.

## F6 — Scope gap: `DecimalValidator` and `FileExtensionValidator` (IMPROVE)
The issue speaks of "built-in validators" generally, and V1's own docs note claims
"Each of these validators passes the value … as `params['value']`", which is
**inaccurate** while `DecimalValidator` and `FileExtensionValidator` are excluded —
they are built-in validators that currently expose other params (`max`,
`extension`, `allowed_extensions`) but not `value`. A user cannot use `%(value)s`
with them, and a feature test iterating all built-in validators would not find
`value` there. Per F2 (their codes — `max_digits`, `max_decimal_places`,
`max_whole_digits`, `invalid_extension`, and the code-less `'invalid'` — are
overridden by no field) and F4 (extra ngettext key is safe), adding
`params['value']` to them is safe. DECISION: add `value` to both for completeness
and to make the documented contract true.

## F7 — `URLValidator` IDN failure reports the converted URL (IMPROVE)
In the IDN branch, `super().__call__(url)` (`validators.py:124`) is called with the
*punycode-converted* URL. If it raises, the inherited `RegexValidator` puts that
converted URL into `params['value']` instead of the user's original input —
contradicting the issue's intent ("the **provided** value"). For example a custom
message would show `xn--…` rather than what the user typed. The other URL paths
(`raise e`, bare `raise`, and all direct raises) correctly carry the original
`value`. DECISION: wrap line 124 to re-raise with `params={'value': value}` so all
paths report the original input. (Same `message`/`code`; only `params['value']`
changes — strictly more correct, message rendering for the default message is
unchanged.)

## F8 — Validator equality unaffected (CONFIRMED)
`params` is per-call runtime data, not configuration. The validators' `__eq__`
methods compare `regex`/`message`/`code`/limits, never `params`. No `__eq__`
changes are needed and the deconstruct/serialization contract is unaffected.

## F9 — Existing visible tests (CONFIRMED no breakage)
`tests/validators/tests.py`: `TEST_DATA` only asserts the *type* (`ValidationError`
vs `None`); the equality tests compare validator configuration; the existing
`test_max_length_validator_message` shows `%(value)s` already works via
`BaseValidator`. No visible test asserts exact `params` content for any validator,
so neither the V1 edits nor the F6/F7 refinements break a visible test.

## F10 — Custom messages containing a literal `%` (ACCEPTED, no action)
Because `params` is now always truthy for these validators, a *custom* message that
contains an unescaped literal `%` (e.g. `"100% required"`) would now be `%`-format
processed and could raise — exactly as it already does for `BaseValidator`/
`DecimalValidator`/`FileExtensionValidator`. The Django convention is to escape a
literal percent as `%%` in messages that carry params. This is inherent to the
requested feature and consistent with existing behavior; no Django built-in message
is affected (F2). No action taken.
