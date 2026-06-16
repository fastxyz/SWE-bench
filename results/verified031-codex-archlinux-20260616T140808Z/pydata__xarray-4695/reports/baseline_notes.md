# Baseline Notes

## Root Cause

`DataArray.loc.__getitem__` converted non-dict keys into a dimension-to-label
mapping and then called `self.data_array.sel(**key)`. If the data array had a
dimension named `method`, that dimension indexer was unpacked as the named
`method` parameter of `DataArray.sel` instead of remaining an entry in the
`indexers` mapping. The label value, such as `"a"`, then reached pandas index
lookup as an invalid fill method and produced the reported error.

`Dataset.loc` already avoided this collision by passing the dictionary as the
positional `indexers` argument to `.sel()`.

## Files Changed

- `repo/xarray/core/dataarray.py`: changed `DataArray`'s private `_LocIndexer`
  to call `self.data_array.sel(key)` instead of `self.data_array.sel(**key)`.
  This keeps all dimension names, including names that overlap `.sel()`
  parameters such as `method`, `tolerance`, or `drop`, inside the indexer
  mapping.

- `reports/baseline_notes.md`: added this report describing the root cause,
  scope of the source change, and assumptions.

## Assumptions and Alternatives Considered

- I assumed the intended behavior is for `.loc[...]` to treat every mapping key
  as a dimension or coordinate indexer, not as a `.sel()` option. `.loc` has no
  syntax for passing `.sel(method=...)`, so preserving the mapping is the least
  ambiguous behavior.

- I considered changing `DataArray.sel` so `da.sel(method="a")` could select a
  dimension named `method`, but rejected that interpretation because it would
  conflict with the existing public `method` parameter for inexact label
  matching. The unambiguous API for direct `.sel` calls remains the mapping
  form, `da.sel({"method": "a"})`.

- I considered changing other internal `.sel(**{dim: value})` call sites, but
  the reported failure is specifically in `DataArray.loc`, and `Dataset.loc`
  already demonstrates the targeted fix pattern. I kept the code change minimal
  to avoid expanding the behavioral surface beyond the issue.

- I did not run tests or project code, per the task instructions.
