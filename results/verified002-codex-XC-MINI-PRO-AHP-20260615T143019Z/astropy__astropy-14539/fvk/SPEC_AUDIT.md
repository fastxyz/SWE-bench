# Spec Audit

Status: constructed, not machine-checked.

| Formal clause | Intent clause | Result | Notes |
| --- | --- | --- | --- |
| `isVLA(P)` true | Intent 4 | Pass | Preserves existing `P` VLA dispatch. |
| `isVLA(Q)` true | Intent 3, 4 | Pass | Covers the public `QD` reproducer. |
| `isVLA(OTHER)` false | Intent 7 | Pass | Preserves non-VLA dispatch. |
| Shape mismatch differs | Intent 1, 5 | Pass | VLA row shape is observable row content. |
| Floating rows use helper equality | Intent 2, 6 | Pass | Aligns VLA floats with FITSDiff floating data policy. |
| Numeric non-floating rows use closeness | Intent 4, 7 | Pass | Preserves V1/P numeric tolerance behavior. |
| Non-numeric rows use exact equality | Intent 1, 5 | Pass | Exact equality is the default table diff behavior for non-floating values. |
| Zero differing rows yields zero contribution | Intent 1, 2 | Pass | Establishes self-comparison no-difference result for the modeled branch. |
| Differing row yields row contribution | Intent 1 | Pass | Ensures real VLA differences are not suppressed. |

No formal-English clause is candidate-only or contradicted by public intent.
