# Public Compatibility Audit

Status: pass.

## Changed symbol

- `repo/xarray/core/weighted.py::Weighted._reduce`

## API and dispatch

- `_reduce` is an internal static helper; its signature is unchanged.
- No public method signature changed for `DataArray.weighted`,
  `Dataset.weighted`, `Weighted.sum`, `Weighted.mean`, or
  `Weighted.sum_of_weights`.
- No new keyword arguments or virtual dispatch calls were introduced.
- `DataArrayWeighted._implementation` and `DatasetWeighted._implementation`
  continue to call the same functions with the same argument names.

## Return behavior

- The affected bool/bool reducer path now returns an integer count, which is the
  intended public behavior for boolean weights.
- Mixed boolean/numeric and non-boolean reductions are outside the new cast
  guard and therefore preserve the previous dot path.

## Required follow-up

No compatibility code changes are required.
