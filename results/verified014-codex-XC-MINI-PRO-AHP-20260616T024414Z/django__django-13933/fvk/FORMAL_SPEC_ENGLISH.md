# Formal Spec In English

Status: constructed from the K claims, not machine-checked.

K-001 `EMPTY-VALUE`: If `ModelChoiceField.to_python()` receives an empty value,
it returns `None` and does not raise `invalid_choice`.

K-002 `VALID-SUBMITTED`: If the submitted lookup key is present in the queryset,
`to_python()` returns the corresponding model object.

K-003 `VALID-MODEL-INSTANCE`: If the input is already an instance of the
queryset model and its lookup key is present in the queryset, `to_python()`
returns the corresponding model object.

K-004 `INVALID-SUBMITTED`: If the submitted non-empty lookup key is absent from
the queryset, `to_python()` raises a `ValidationError` whose code is
`invalid_choice`, whose message is the field's invalid-choice message, and whose
params map contains `value` equal to the rejected submitted key.

K-005 `INVALID-MODEL-KEY`: If the input is an instance of the queryset model but
the key used for lookup is absent from the queryset, `to_python()` raises
`invalid_choice` with params `value` equal to that lookup key. This mirrors the
implementation's conversion before `queryset.get()`.

K-006 `INVALID-BAD-TYPE`: If queryset lookup or field conversion rejects the
submitted non-empty value with a `ValueError` or `TypeError`, `to_python()`
raises `invalid_choice` with params `value` equal to the value that failed
lookup or conversion.

K-007 `DEFAULT-MESSAGE`: The default invalid-choice message contains the
`%(value)s` placeholder so rendering the `ValidationError` displays the invalid
value.

K-008 `FRAME`: The constructor signature, `to_python()` signature, successful
return type, and error code are unchanged.

