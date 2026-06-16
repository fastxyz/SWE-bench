# Baseline Notes

## Root cause

`AddIndex` and `RemoveIndex` did not implement any migration optimizer reduction.
Although adding an index and later removing the same index on the same model has
no net state or database effect, the optimizer had no operation-specific rule to
collapse that pair.

Index-related operations also inherited directly from `Operation`, whose default
model reference behavior is conservative. As a result, an `AddIndex` operation
could not be optimized across unrelated model operations while searching for a
matching later `RemoveIndex`.

## Files changed

`repo/django/db/migrations/operations/models.py`

- Added `IndexOperation.references_model()` so index operations report the model
  they affect instead of conservatively referencing every model.
- Added `IndexOperation.reduce()` so index operations can be optimized across
  later operations that do not reference their model, matching the pattern used
  by other model-scoped migration operations.
- Added `AddIndex.reduce()` to collapse `AddIndex` followed by `RemoveIndex`
  when both target the same model and exact index name.

`reports/baseline_notes.md`

- Added this implementation note required by the benchmark task.

## Assumptions and alternatives considered

- I assumed the intended reduction is only safe when the `RemoveIndex` targets
  the exact index name added by `AddIndex`. I rejected case-insensitive name
  matching because migration state removes indexes by exact `obj.name`.
- I treated operations on unrelated models as safe to optimize across, using the
  existing `references_model()` contract. I rejected a broader same-model
  field-level pass-through because indexes can depend on fields through
  expressions, conditions, and includes, and the current issue does not require
  that extra analysis.
- I did not change tests or run the test suite because the task explicitly
  forbids modifying tests and running code in this session.
