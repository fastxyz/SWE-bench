# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Intent-derived domain

The spec domain must include all relevant branches for
`ModelChoiceField.to_python()`: empty input, valid submitted key, valid
model-instance input, absent key, and conversion/type failure.

Status: discharged by K claims `EMPTY-VALUE`, `VALID-SUBMITTED`,
`VALID-MODEL-INSTANCE` via the valid lookup rule, `INVALID-SUBMITTED`,
`INVALID-MODEL-KEY`, and `INVALID-BAD-TYPE`.

## PO-2: Invalid choices carry params

For every non-empty invalid choice path caught by
`except (ValueError, TypeError, DoesNotExist)`, the raised
`ValidationError` must include `params={'value': value}` where `value` is the
value used by that failed validation path.

Status: discharged by V1 source at `ModelChoiceField.to_python()` and by K
claims `INVALID-SUBMITTED`, `INVALID-MODEL-KEY`, and `INVALID-BAD-TYPE`.

## PO-3: Default message can render the value

The default `invalid_choice` message for `ModelChoiceField` must contain the
`%(value)s` placeholder.

Status: discharged by V1 source in
`ModelChoiceField.default_error_messages['invalid_choice']`.

## PO-4: Existing success and empty behavior is preserved

The fix must not alter successful queryset lookup or empty-value cleaning.

Status: discharged. V1 edits only the default message and the exception
construction in the existing invalid-choice except block.

## PO-5: Value identity is explicit

For ordinary submitted scalar values, `params['value']` is the submitted value.
For instances of the queryset model, the implementation first converts to the
configured lookup key; if that lookup fails, `params['value']` is that key.

Status: discharged. This follows from the order of assignment in
`to_python()` and is encoded in `INVALID-SUBMITTED` and `INVALID-MODEL-KEY`.

## PO-6: Public compatibility

No public method signature, constructor signature, successful return type, or
error code may change. Existing custom messages without placeholders and
without literal percent formatting must continue to render.

Status: discharged by static compatibility audit. The only behavior change is
the intentional addition of `params`; custom messages with literal percent
characters should use standard `%%` escaping, matching other choice fields.

## PO-7: Honesty gate

The proof artifacts must be labeled constructed, not machine-checked, and no
test-removal recommendation may be unconditional.

Status: discharged. No tests, Python, or K tooling were run.

