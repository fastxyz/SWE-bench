# Intent Spec

Constructed, not machine-checked.

## Scope

The audited behavior is Django `QuerySet.bulk_create(..., batch_size=...)` as implemented through `QuerySet._batched_insert()`. The relevant observable is the size of each insert batch sent to `_insert()`.

## Intent-derived obligations

- `bulk_create()` inserts the supplied objects in batches. This comes from the `bulk_create()` docstring and `_batched_insert()` helper comment.
- A backend-compatible batch-size calculation is authoritative for the maximum valid insert batch size. This comes from the issue text and `BaseDatabaseOperations.bulk_batch_size()` saying it returns "the maximum allowed batch size for the backend."
- If the caller provides a positive `batch_size`, the effective batch size must be no larger than the backend-compatible maximum. The issue explicitly reports the opposite behavior as a bug.
- If the caller does not provide `batch_size`, the effective batch size remains the backend-compatible maximum already used by the helper.
- If the caller provides a positive `batch_size` less than or equal to the backend maximum, that smaller user value is preserved.
- The fix must not alter `bulk_create()`'s public signature, `_batched_insert()`'s private signature, `ignore_conflicts` support checks, returning-row handling, object state updates, or field selection for the two insert paths.

## Default-domain assumptions

- The audited domain has `len(objs) >= 0`, positive explicit `batch_size` when one is provided, and a supported backend whose compatible batch size for an insertable object set is at least one after Django's existing `max(..., 1)` lower bound.
- This FVK pass proves partial correctness of the batching calculation and slicing. It does not prove database execution, transaction behavior, object mutation side effects, or termination of arbitrary backend calls.
