# Baseline Notes

## Root cause

`xarray.polyval` converts datetime-like coordinate values to numeric values through
`_ensure_numeric` in `xarray/core/computation.py`. That helper treated both
`datetime64` and `timedelta64` values the same way and always passed a
`datetime64("1970-01-01")` offset into `datetime_to_numeric`.

That is valid for `datetime64` inputs, where xarray's polynomial fitting path uses
nanoseconds relative to the Unix epoch. It is invalid for `timedelta64` inputs:
subtracting a datetime offset from a timedelta array raises a dtype-resolution
error, which is the error reported when users pass a timedelta coordinate directly
to `polyval`.

## Files changed

`repo/xarray/core/computation.py`

- Updated `_ensure_numeric` to handle `datetime64` and `timedelta64` in separate
  branches.
- Kept the existing `datetime64` conversion relative to
  `np.datetime64("1970-01-01")`, preserving current datetime behavior.
- Added a `timedelta64` conversion relative to `np.timedelta64(0, "ns")`, so
  timedelta values are converted to their duration in nanoseconds.
- Updated the helper docstring to describe both datetime and timedelta handling.

## Assumptions and rejected alternatives

I assumed `polyval` should evaluate timedelta coordinates in the same numeric
domain used by `polyfit`: raw timedelta duration in nanoseconds. This matters for
timedelta coordinates that do not start at zero.

I considered calling `datetime_to_numeric` for timedeltas without an explicit
offset, but rejected that because the helper would use the minimum timedelta as
the offset. That would make evaluation relative to the first/minimum coordinate
instead of preserving the actual timedelta value, which could disagree with
coefficients produced by `polyfit`.

I did not broaden `polyval` to accept plain NumPy arrays. The public API and the
existing implementation are typed around `DataArray` and `Dataset`, and the issue
discussion identified the NumPy-array call as a separate misuse rather than the
bug to fix.

I did not modify tests or run code, following the benchmark constraints.
