# Public Evidence Ledger

Constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "bulk_create batch_size param overrides the compatible batch size calculation" | A user-provided batch size must not bypass the backend-compatible batch size. | Encoded by claims `effectiveBatch(userBatch(U), C)`. |
| E2 | `benchmark/PROBLEM.md` | "bulk_update properly picks the minimum of two" | When a user batch size is supplied, the effective value should be the minimum of user size and compatible cap. | Encoded by split claims for `U <= C` and `U > C`. |
| E3 | `benchmark/PROBLEM.md` | Suggested logic: `batch_size = min(batch_size, max_batch_size) if batch_size else max_batch_size` | No user value means use the compatible maximum; a user value means clamp to that maximum. | Encoded by `noBatch` and `userBatch` claims. |
| E4 | `repo/django/db/backends/base/operations.py` | `bulk_batch_size()` returns "the maximum allowed batch size for the backend." | The backend operation's result is a cap, not merely a hint. | Used as the cap `C` in the formal model. |
| E5 | `repo/django/db/models/query.py` | `_batched_insert()` is the helper for `bulk_create()` and slices `objs` by `batch_size`. | The correctness observable is every slice length passed to `_insert()`. | Encoded by `batchLengths()` claims. |
| E6 | `repo/django/db/models/query.py` | `bulk_create()` calls `_batched_insert()` separately for objects with and without explicit primary keys. | The cap must be computed inside `_batched_insert()` using the actual field list. | Discharged by keeping the V1 edit inside `_batched_insert()`. |
| E7 | `repo/django/db/models/query.py` | `bulk_create()` asserts `batch_size is None or batch_size > 0`. | The formal user-batch domain is positive explicit sizes or no value. | Captured as `U >Int 0` preconditions. |
