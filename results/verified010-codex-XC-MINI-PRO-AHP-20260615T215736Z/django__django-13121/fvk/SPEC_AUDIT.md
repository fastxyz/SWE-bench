# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent coverage | Result |
| --- | --- | --- |
| `DURATION-FIELD-PLUS-LITERAL` | E1, E2, E3 require the reported duration-only case to return stored-duration output. | Pass |
| `LITERAL-PLUS-DURATION-FIELD` | E1 describes the duration-only family; commuted addition is the same valid duration-only operation. | Pass |
| `DURATION-FIELD-PLUS-DURATION-FIELD` | E1 describes duration-only expressions; E3 requires stored microseconds. | Pass |
| `TEMPORAL-SUBTRACTION-PLUS-DURATION` | E5 establishes temporal subtraction as duration-producing; F2 showed V1 did not cover it. | Pass |
| `MIXED-DATETIME-PLUS-DURATION` | E4 requires mixed date/time arithmetic to keep backend interval formatting. | Pass |
| `MULTIPLY-STAYS-ON-BACKEND-DURATION-PATH` | E6 limits the fix to `+` and `-`; preserving invalid operator handling is required. | Pass |

No claim is legacy-derived without public support. The only V1-derived behavior
kept is the numeric microsecond branch for direct duration-only operands, which
is independently supported by E1-E3.
