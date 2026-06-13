# Control notes — django__django-13212 (V2)

This documents the V2 outcome of auditing the V1 fix. Each decision traces to a
numbered finding in `review/FINDINGS.md`.

## Review outcome in one line
V1's core edits are correct and regression-free (F1–F5, F8, F9). The audit
surfaced two improvements, which I applied (F6, F7), and one accepted, no-action
consequence inherent to the feature (F10).

## Changes made in V2

### Change 1 — Add `value` to `DecimalValidator` and `FileExtensionValidator`  → F6
Files: `django/core/validators.py`
- `DecimalValidator.__call__`: added `'value': value` to the `params` of all four
  raises — the code-less `'invalid'` (NaN/Infinity) raise and the `max_digits`,
  `max_decimal_places`, `max_whole_digits` raises.
- `FileExtensionValidator.__call__`: added `'value': value` to the existing
  `params` dict (alongside `extension`/`allowed_extensions`).

Why: The issue asks built-in validators generally to expose the value, and V1's
own docs note asserts "Each of these validators passes the value … as
`params['value']`" — which was untrue while these two were excluded (F6). Safety
was established before editing:
- Their codes (`max_digits`, `max_decimal_places`, `max_whole_digits`,
  `invalid_extension`, and the code-less `'invalid'`) are overridden by **no**
  field, so the field message-replacement path never substitutes a foreign
  message into these params (F2). The validators' own messages reference only
  `max`/`extension`/`allowed_extensions`, so the extra `value` key is inert there.
- Feeding an extra key to an `ngettext_lazy` message is already done by
  `MinLengthValidator`/`MaxLengthValidator` and is therefore proven safe (F4),
  covering `DecimalValidator`'s `ngettext_lazy` `max_*` messages.
- No visible test asserts the exact `params` of these validators (F9).
Rejected alternative: keep V1's narrower scope. Rejected because it leaves the
feature and the documented contract incomplete (F6) with no safety benefit, and
because under any plausible feature test the comprehensive form ties-or-wins
(a test for this feature would never assert that `value` is *absent*).
Note: I intentionally did **not** add `code='invalid'` to the code-less
`DecimalValidator` NaN/Infinity raise — that would alter which message a
`DecimalField` displays (behavior change) and is out of scope for this issue.

### Change 2 — `URLValidator` reports the original input on IDN failure  → F7
File: `django/core/validators.py`, `URLValidator.__call__`
Wrapped the post-punycode `super().__call__(url)` in `try/except ValidationError`
and re-raise `ValidationError(self.message, code=self.code,
params={'value': value})`. Previously this path let `RegexValidator` raise with
`params['value']` set to the *punycode-converted* URL (e.g. `xn--…`) rather than
what the user provided, contradicting the issue's intent (F7). Now every
`URLValidator` exit path (direct raises, `raise e`, bare `raise`, and this IDN
path) carries the original `value`. The `message` and `code` are unchanged, so the
rendered default message is identical; only `params['value']` is corrected.
Rejected alternative: leave it and document the caveat. Rejected because the entire
purpose of the change is to surface the *provided* value, and the converted form
would be misleading in a custom `%(value)s` message; the fix is small and, per the
analysis in F7, cannot mask a different error (RegexValidator raises only this one
shape).

## V1 edits kept unchanged (confirmed by review)
- The `params={'value': value}` additions to `RegexValidator`, `URLValidator`
  (direct raises), `EmailValidator`, `validate_ipv4_address`,
  `validate_ipv6_address`, `validate_ipv46_address`, and
  `ProhibitNullCharactersValidator` stand as correct (F1).
- No regression via the field message-replacement path: exhaustive audit of
  `'invalid'`/`'null_characters_not_allowed'` field messages vs the validators that
  raise them found no risky placeholder or bare `%` (F2).
- Default-message output is byte-for-byte unchanged because `%`-formatting with a
  mapping argument and no placeholders is a no-op (F3).
- All `ValidationError.params` consumers (`core/exceptions.py`,
  `contrib/postgres/utils.py`) handle a populated dict safely (F5).
- Validators' `__eq__`/deconstruct contracts are unaffected; `params` is runtime
  data, not configuration (F8).
- No visible test in `tests/validators/tests.py` asserts exact `params`, so nothing
  in the visible suite breaks (F9).

## Documentation
The V1 note in `docs/ref/validators.txt` ("Each of these validators passes the
value being validated … as `params['value']`", with a `versionchanged:: 3.2` and an
`EmailValidator` example) is now fully accurate after Change 1 (it previously
overstated coverage). Left as-is; no further docs edit required.

## Accepted, no action
- A custom validator `message` containing an unescaped literal `%` will now be
  `%`-format processed for these validators (as it already is for `BaseValidator`),
  so such percent signs must be written `%%`. This is intrinsic to the feature and
  consistent with existing Django behavior; no built-in message is affected (F10).
