# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item | Result | Notes |
| --- | --- | --- | --- |
| `RESTORE-POSTAGGS` restores all `P` suffix values in order. | Intent 1 and 2 | Pass | Directly captures the reported multi-post-aggregator cache corruption. |
| `RESTORE-POSTAGGS-LOOP` uses `postPos` as the count of restored values. | Intent 2 | Pass | This is the formal version of "do not restore all postaggs into the same index." |
| Valid-cache precondition. | Intent 4 | Pass | The issue concerns cache entries produced by the query cache path, not arbitrary malformed objects. |
| Frame condition for timestamp/dim/agg/API behavior. | Intent 3 | Pass | V1's diff touches only post-aggregator restoration indexing and an unused import. |
| No claim about malformed/truncated cache rows. | Intent 4 | Pass | Recorded as residual assumption F3, not hidden. |
