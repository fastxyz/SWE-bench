# Baseline Notes

## Root cause

`DataArray.quantile` delegates to `Dataset.quantile` by first wrapping the
array as a temporary dataset. The original `DataArray` attributes are stored on
the underlying temporary data variable, not on the temporary dataset itself.

`Dataset.quantile` accepted `keep_attrs`, but only used it when assigning
attributes to the resulting dataset. It called `Variable.quantile` without any
way to preserve variable-level attributes, and `Variable.quantile` always
constructed a new `Variable` without attrs. As a result,
`DataArray.quantile(..., keep_attrs=True)` dropped the original array attrs.

## Files changed

- `repo/xarray/core/variable.py`
  - Added a `keep_attrs` argument to `Variable.quantile`.
  - Resolved `keep_attrs=None` using the existing `_get_keep_attrs(default=False)`
    helper, matching `Variable.reduce`.
  - Passed the original variable attrs into the result when `keep_attrs` is true.

- `repo/xarray/core/dataset.py`
  - Resolved `keep_attrs` before iterating through variables in
    `Dataset.quantile`.
  - Passed `keep_attrs` through to each reduced variable's `quantile` call.
  - Kept the existing dataset-level attrs behavior unchanged.

## Assumptions and rejected alternatives

- I assumed `keep_attrs` should apply to the reduced data variable as well as to
  the resulting dataset, because `DataArray` attrs are variable attrs and the
  public hint explicitly points to adding `keep_attrs` to `Variable.quantile`.
- I rejected copying `DataArray` attrs onto the temporary dataset in
  `DataArray.quantile`; that would special-case this one wrapper path and would
  not fix direct `Variable.quantile` or dataset variable attrs.
- I rejected post-processing attrs in `DataArray.quantile`; the rest of xarray's
  reduction behavior routes attr preservation through `Variable.reduce`, so the
  equivalent targeted fix is to make `Variable.quantile` honor `keep_attrs`.
- I did not run tests or project code, per the task instructions.
