# Spec Audit

| Claim | Intent entries | Result | Notes |
| --- | --- | --- | --- |
| C-001 | I-001, I-004, I-006, D-002, D-003 | PASS | The ASCII accepted-language claim matches the documented allowed set and whole-string requirement. |
| C-002 | I-001, I-003, I-004, D-002 | PASS | The rejection claim covers empty input and any non-allowed character, including newline. |
| C-003 | I-003, I-004, D-001 | PASS | This is the issue's concrete failing family: an otherwise valid username with trailing LF. |
| C-004 | I-002, I-004, I-006, D-002, D-003 | PASS | The Unicode accepted-language claim matches the documented allowed set and whole-string requirement. |
| C-005 | I-002, I-003, I-004, D-002 | PASS | The rejection claim covers empty input and any non-allowed character, including newline. |
| C-006 | I-003, I-004, D-001 | PASS | This is the Unicode counterpart of the issue's concrete failing family. |
| C-007 | I-003, I-004 | PASS | The abstraction preserves the property axis under audit by distinguishing a valid username from the same username with final LF. |

No claim is candidate-derived, legacy-derived, over-specific, or under-specific relative to the public intent. The formalization does not prove unrelated behavior of Python's full regular-expression engine; it models only the validator-language fragment needed for this issue.
