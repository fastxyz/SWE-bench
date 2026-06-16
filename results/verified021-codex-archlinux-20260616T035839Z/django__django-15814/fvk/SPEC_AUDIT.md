# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item | Audit | Notes |
| --- | --- | --- | --- |
| PROXY-ONLY-PK requires proxy target masks to contain the related concrete primary key and requested field. | INTENT 1, 2, 3 | Pass | Directly addresses the reported `id` omission and crash. |
| CONCRETE-TARGET-FRAME states concrete targets are unchanged because `concrete(T) = T`. | INTENT 4 | Pass | The normalization is identity for non-proxy models. |
| The K model abstracts away SQL, database rows, aliases, and query execution. | Domain section | Pass | Those are not needed to distinguish the reported crash from the fix. The preserved observable is selected field membership. |
| LEGACY-PROXY-COUNTEREXAMPLE states the pre-fix mechanism omits `idField`. | E1, E2, E6, E7 | Pass as counterexample, not as desired behavior | This is included to localize the bug. It is not used as a correctness claim for production code. |
| No public API/signature change. | INTENT 5 | Pass | The V1 source edit changes only internal traversal state in `deferred_to_data()`. |

No required behavior is marked fail or ambiguous.

