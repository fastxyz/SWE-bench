# Formal Spec English

Status: paraphrase of the `.k` claims; constructed, not machine-checked.

C-DECIMAL-PRESERVE: If the input value is a `Decimal` represented by abstract
decimal value `D` and the normalized argument is integer places `P`, evaluation
of the modeled `floatformat` conversion path reaches `render(D, P)`. The same
abstract decimal value `D` is used by rendering.

C-ISSUE-DECIMAL-20: For abstract decimal value
`dec(0, 4212345678901234567890, 20)` representing
`42.12345678901234567890`, and normalized argument `20`, the modeled output is
`42.12345678901234567890`.

C-NONDECIMAL-FRAME: If the input is not already a Decimal, the modeled
conversion path remains the old path: parse from the existing `repr()` string
and then use the existing fallback behavior if that parse fails.

C-INVALID-ARG-DECIMAL-DISPLAY: If the argument is invalid after suffix parsing,
a Decimal input returns the user-visible decimal string for that Decimal. This
is not used to justify the precision fix, but records the V1 consequence of
choosing `str(text)` as `input_val` for Decimal values.
