# Baseline Notes

## Root cause

`QuerySet.bulk_update()` already performs the update work by splitting objects
into batches and calling `QuerySet.update()` for each batch, but it ignored the
integer row count returned by those calls. As a result, callers received `None`
even though the operation had access to the same matched-row information that
`update()` exposes.

## Files changed

`repo/django/db/models/query.py`

- Updated the `bulk_update()` docstring to describe the returned row count.
- Changed the empty-object case to return `0`, matching the integer return
  convention of `update()` when no rows are matched.
- Accumulated the return value from each batched `update()` call and returned
  the total after the transaction completes.

## Assumptions and alternatives considered

- I treated the requested return value as a plain integer, matching
  `QuerySet.update()`, rather than introducing a named tuple or other
  future-proof wrapper. The issue discussion specifically accepted preserving
  the existing `update()` convention for now.
- I left duplicate primary key handling unchanged. If duplicate objects are
  split across batches, each batch's SQL update can contribute to the returned
  total, because the fix returns the sum of the actual `update()` calls made by
  `bulk_update()`.
- I did not change validation order. Empty input still validates the field list
  and field names before returning `0`, preserving existing error behavior for
  invalid arguments.
- I did not run tests or execute code, per the benchmark instructions.
