# Baseline Notes

## Root cause

`Dataset.swap_dims()` converted any variable whose name became a result dimension with `v.to_index_variable()`, then immediately assigned to `var.dims`. For ordinary `Variable` instances this conversion returns a fresh `IndexVariable`, so mutating `var.dims` is local to the new dataset. For an existing `IndexVariable`, however, `IndexVariable.to_index_variable()` returns `self`.

After operations such as `swap_dims(...).rename_dims(...).reset_index(...).reset_coords()`, the would-be dimension coordinate can still be represented by an `IndexVariable` even when it is a data variable. Calling `swap_dims()` on that dataset reused the same object and then mutated its `dims`, so the original dataset's variable metadata changed.

## Files changed

`repo/xarray/core/dataset.py`

- In `Dataset.swap_dims()`, the branch that promotes a result-dimension variable to an index variable now calls `.copy(deep=False)` after `to_index_variable()` and before assigning the rewritten dimensions.
- This keeps the existing shallow-copy behavior for array/index data, attributes, and encoding while ensuring the returned dataset has its own variable object to mutate.
- The non-index branch was left unchanged because `to_base_variable()` already constructs a new `Variable` object before its dimensions are assigned.

## Assumptions and rejected alternatives

- I assumed `swap_dims()` should continue to share underlying data shallowly, consistent with nearby rename logic and xarray's existing internal replacement patterns.
- I considered replacing the dimension assignment with `_replace(dims=...)`, but rejected it because `IndexVariable.copy(deep=False)` is the existing safe path for preserving pandas-backed index data while creating a distinct variable object.
- I did not modify tests because the task forbids changing test files. I also did not run tests or project code because the task states that no execution environment is available.
