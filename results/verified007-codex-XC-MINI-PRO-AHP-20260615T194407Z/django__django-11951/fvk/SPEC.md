# FVK Specification

Constructed, not machine-checked.

## Target

Issue `django__django-11951` reports that `bulk_create(batch_size=...)` lets an explicit `batch_size` override the backend-compatible batch-size calculation. The audited code is `QuerySet._batched_insert()` in `repo/django/db/models/query.py`, reached from `QuerySet.bulk_create()`.

## Intent ledger

| ID | Source | Semantic obligation |
| --- | --- | --- |
| E1 | `benchmark/PROBLEM.md`: "`bulk_create` batch_size param overrides the compatible batch size calculation" | Explicit user batch size must not exceed the compatible backend cap. |
| E2 | `benchmark/PROBLEM.md`: "`bulk_update` properly picks the minimum of two" | Effective batch size with a user value is `min(user_batch_size, backend_cap)`. |
| E3 | `benchmark/PROBLEM.md`: suggested conditional min expression | No user value uses the backend cap; user value is clamped to it. |
| E4 | `BaseDatabaseOperations.bulk_batch_size()` docstring | `ops.bulk_batch_size(fields, objs)` is the backend maximum for the actual fields and objects. |
| E5 | `_batched_insert()` helper comment and slicing loop | The observable under proof is each object slice passed to `_insert()`. |
| E6 | `bulk_create()` two calls into `_batched_insert()` | The maximum must be computed at helper level, after each concrete `fields` list is known. |
| E7 | `bulk_create()` assertion on `batch_size` | Explicit user batch values are positive within the audited domain. |

## Formal contract

Let:

- `N = len(objs)`.
- `C = max(connection.ops.bulk_batch_size(fields, objs), 1)`.
- `U` be a positive explicit user batch size, or absent.
- `B` be the effective batch size used in `range(0, len(objs), B)`.

The intended contract is:

- If `U` is absent, `B = C`.
- If `0 < U <= C`, `B = U`.
- If `U > C`, `B = C`.
- Every emitted batch length is at most `C`.
- The emitted batch lengths sum to `N`, so batching does not drop or duplicate objects.

## Formal core

- `fvk/mini-bulk-create.k` defines a minimal K fragment for `effectiveBatch()` and `batchLengths()`.
- `fvk/bulk-create-batching-spec.k` contains K claims for the three effective-batch cases and two generated-batch safety claims.

These files are constructed but not machine-checked. The expected check commands are recorded in `fvk/PROOF.md`.

## V1 source assessment

V1 implements the contract:

```python
max_batch_size = max(ops.bulk_batch_size(fields, objs), 1)
batch_size = min(batch_size, max_batch_size) if batch_size else max_batch_size
```

This satisfies the issue-derived min obligation while keeping the cap calculation inside `_batched_insert()`, where the actual `fields` list is known.

## Scope limits

This FVK pass does not prove database SQL execution, transaction behavior, backend implementation correctness, object state mutation, or total correctness of arbitrary database calls. It proves the batching arithmetic and slice-size property that the issue identifies.
