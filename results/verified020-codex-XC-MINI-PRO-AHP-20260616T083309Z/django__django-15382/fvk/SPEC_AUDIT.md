# Spec Audit

Status: constructed, not machine-checked.

| Formal obligation | Intent entry | Result | Notes |
| --- | --- | --- | --- |
| `NEGATED-EMPTY-EXISTS` | Intent 1, 4, 5; evidence E-001, E-003, E-004 | Pass | Matches the reported bug and public hint. |
| `POSITIVE-EMPTY-EXISTS` | Intent 2 | Pass | Preserves positive empty `Exists` as always false. |
| `POSITIVE-NONEMPTY-EXISTS` | Intent 3 | Pass | Frame condition for unaffected normal compilation. |
| `NEGATED-NONEMPTY-EXISTS` | Intent 3 | Pass | Frame condition for unaffected normal negation. |
| `AND-PRESERVE-TRUE-EXISTS` | Intent 1; evidence E-001, E-006 | Pass | Covers the observable WHERE-collapse symptom. |
| `AND-EMPTY-EXISTS-COLLAPSES` | Intent 2; evidence E-006 | Pass | Confirms the positive empty case is not accidentally changed. |

No formal obligation is candidate-derived without public intent or source
semantics support. No required behavior is marked ambiguous.
