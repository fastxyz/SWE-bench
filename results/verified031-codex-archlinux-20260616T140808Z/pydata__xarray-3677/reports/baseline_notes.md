# Baseline Notes

## Root cause

`Dataset.merge()` delegates to `dataset_merge_method()`, which expected its
`other` argument to be a `Dataset` or mapping. A `DataArray` is documented and
used elsewhere as castable to a `Dataset`, and top-level `xarray.merge()`
already handles it by converting each `DataArray` to `DataArray.to_dataset()`
before calling `merge_core()`. The method path skipped that conversion, so a
`DataArray` reached code that calls `set(other)`, `other.items()`, or the
mapping loop in `coerce_pandas_values()`. Because `DataArray` does not provide
mapping methods such as `items()`, `ds.merge(da)` failed with an
`AttributeError`.

## Changed files

- `repo/xarray/core/merge.py`: updated `dataset_merge_method()` to accept a
  `DataArray` and immediately convert it with `to_dataset()`. This matches the
  top-level `merge()` normalization and fixes both the default merge path and
  the `overwrite_vars` path before any mapping-specific operations run.
- `repo/xarray/core/dataset.py`: updated the `Dataset.merge()` annotation and
  parameter documentation to explicitly include `DataArray` as an accepted
  `other` value.

## Assumptions and alternatives

- I assumed `Dataset.merge(da)` should behave like `xarray.merge([ds, da])`,
  including requiring the `DataArray` to have a name. Using `to_dataset()`
  preserves the existing `ValueError` for unnamed arrays.
- I considered teaching `merge_core()` or `coerce_pandas_values()` to accept
  bare `DataArray` objects. I rejected that because `merge_core()` is documented
  around mappings and datasets, and top-level `merge()` already normalizes
  `DataArray` inputs at the API boundary.
- I considered converting `other` in `Dataset.merge()` itself. I rejected that
  because `dataset_merge_method()` contains the overwrite handling that also
  needs normalized input; keeping the conversion there fixes all method paths in
  one place.
- I did not run tests or project code because the task instructions explicitly
  forbade execution in this benchmark workspace.
