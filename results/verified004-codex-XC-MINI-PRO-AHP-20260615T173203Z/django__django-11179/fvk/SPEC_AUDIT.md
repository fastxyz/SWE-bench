# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item(s) | Audit | Notes |
| --- | --- | --- | --- |
| K-OPT-FAST-SINGLE-CLEAR-PK | I1, I2 | Pass | Covers the exact issue path: successful `.delete()` on a fast-deletable instance clears PK. |
| K-NORMAL-COLLECTED-CLEAR-PK | I1, I3 | Pass | Confirms the reference cleanup behavior still exists for the non-optimized path. |
| Frame condition: return shape preserved | I4 | Pass | V1 adds a side effect only after `delete_batch()`, and returns the same `(count, {label: count})` value. |
| Partial-correctness boundary after successful SQL delete | I5 | Pass | No claim is made for exception paths; the new `setattr()` occurs only after `delete_batch()` returns. |
| Queryset fast-delete frame | I6 | Pass | The formal instance-state claim is not overextended to queryset rows that have no in-memory instance to mutate. |

No fail or ambiguous adequacy items were found.
