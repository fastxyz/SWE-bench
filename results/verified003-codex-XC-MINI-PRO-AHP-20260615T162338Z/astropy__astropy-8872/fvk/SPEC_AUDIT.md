# Spec Audit

Status: adequacy check between `INTENT_SPEC.md` and
`FORMAL_SPEC_ENGLISH.md`.

| Claim | Intent Coverage | Result |
| --- | --- | --- |
| QD-001 | Matches I-001 and I-005: unit multiplication reaches `Quantity(m, unit)`. | pass |
| QD-002 | Matches I-002: every inexact dtype is preserved by default. | pass |
| QD-003 | Matches I-001: the concrete `float16` symptom is fixed. | pass |
| QD-004 | Matches I-002 for the existing-Quantity copy branch also guarded by the old predicate. | pass |
| QD-005 | Matches existing documented copy behavior and is unaffected by V1. | pass |
| QD-006 | Matches I-004: explicit dtype still wins. | pass |
| QD-007 | Matches I-003: integer, bool, and object default coercion stay unchanged. | pass |
| QD-008 | Matches existing implementation/public behavior for structured dtype preservation. | pass |
| QD-009 | Matches I-005: no public API or test changes. | pass |

No formal-English obligation is weaker than public intent. No obligation is
derived solely from the candidate implementation where it would preserve the
reported legacy bug. The pre-fix display showing `float64` is treated as a
SUSPECT legacy behavior and is not used as expected behavior.
