# Spec Audit

Status: constructed, not machine-checked.

| Formal English claim | Intent entries | Result | Notes |
| --- | --- | --- | --- |
| CLAIM-SPLIT-EXCLUDE-COPIES-FILTERED-RELATIONS | I-001, E-001, E-002, E-003 | pass | Directly addresses the reported FieldError cause. |
| CLAIM-TRIM-MOVES-FILTERED-CONDITION | I-002, I-003, I-004, E-004, E-005, E-006 | pass | Matches the public hint that copy-only resolution is insufficient and that relation-only filtered predicates must appear in the anti-subquery. |
| CLAIM-TRIM-KEEPS-PARENT-ALIAS-CONDITION | I-005, I-006 | pass | This is a preservation side condition required by the code path: moving a predicate that still references a trimmed alias would be unsound. Keeping the join preserves semantics and does not contradict public intent. |
| CLAIM-UNFILTERED-FRAME | I-006, I-007 | pass | The diff is conditional on filtered relation metadata and leaves unfiltered behavior unchanged. |
| CLAIM-EXCLUDE-SEMANTICS | I-002, I-003, E-005, E-007, E-008 | pass | Encodes the intended result of excluding related rows matching both predicates. |

No claim is candidate-only. The only implementation-derived side condition is
the alias-reference guard in `trim_start()`, and it is justified by I-005: an
SQL predicate cannot be moved into a query fragment where one of its aliases no
longer exists.

