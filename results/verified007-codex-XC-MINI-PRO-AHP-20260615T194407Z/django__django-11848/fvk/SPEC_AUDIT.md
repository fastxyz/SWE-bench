# Spec Audit

Status: constructed for FVK audit, not machine-checked.

| Formal claim | Intent obligation | Audit |
| --- | --- | --- |
| C1 current-century candidate branch | E2, E3, E4, E6 require a current-year-relative interpretation instead of fixed `00-69` / `70-99`. | Pass. |
| C2 rollover branch | E2 requires years more than 50 years in the future to represent the most recent past year with the same last two digits. | Pass. |
| C3 `CY=2018`, `YY=69` discriminator | E3 names the fixed `2069` behavior as the bug; E2/E6 require rollover. | Pass. |
| C4 strict boundary | E2 says "more than 50 years", not "50 or more". | Pass. |
| C5 frame conditions | E7, E8, E9, E11 require preserving parser shape, return type, and non-year behavior. | Pass. |
| Broad `year < 100` branch | E10 supports preserving existing behavior for zero-padded parsed years below 100 outside RFC850. | Pass, compatibility-derived rather than RFC-derived. |

No formal-English claim is candidate-derived without public or default-domain
support. No ambiguity blocks the conclusion that V1 satisfies the year
normalization intent.

