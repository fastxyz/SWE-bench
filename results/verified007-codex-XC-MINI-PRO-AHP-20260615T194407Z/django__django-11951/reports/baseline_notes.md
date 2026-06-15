# Baseline Notes

## Root cause

`QuerySet._batched_insert()` used the caller-provided `batch_size` directly when it was supplied:

```python
batch_size = (batch_size or max(ops.bulk_batch_size(fields, objs), 1))
```

That bypassed `connection.ops.bulk_batch_size()`, so `bulk_create(batch_size=...)` could build insert batches larger than the database backend supports. Backends such as SQLite and Oracle use `bulk_batch_size()` to stay under query parameter limits, so an oversized explicit `batch_size` could produce invalid SQL or exceed backend limits.

`bulk_update()` already clamps a caller-provided batch size to the backend maximum, which matches the behavior needed here.

## Files changed

- `repo/django/db/models/query.py`
  - Updated `QuerySet._batched_insert()` to compute `max_batch_size` from `ops.bulk_batch_size(fields, objs)`.
  - Changed effective `batch_size` selection to use the smaller of the caller-provided value and the backend maximum, falling back to the backend maximum when no value is provided.
  - Kept the existing lower bound of `1` around the backend maximum calculation.

## Assumptions and alternatives

- I assumed the fix belongs in `_batched_insert()` rather than `bulk_create()` because `_batched_insert()` is where the concrete field list is known for each insert path. `bulk_create()` may call it once with primary key fields and once without `AutoField`, so clamping there preserves the backend calculation for the actual insert shape.
- I assumed `batch_size` validation should remain unchanged. `bulk_create()` already asserts that an explicit batch size is positive, and this issue is about oversized positive values.
- I considered changing backend `bulk_batch_size()` implementations, but rejected that because they already return the correct maximum; the problem was that their result was ignored when `batch_size` was supplied.
- I did not modify tests because the task requires changing non-test source code only, and I did not run tests or project code per the task constraints.
