# Baseline Notes

## Root Cause

`DataArray.integrate` used `dim` as its public argument name even though it delegates to `Dataset.integrate`, whose corresponding argument is named `coord`. This made the DataArray API inconsistent with `Dataset.integrate` and with both `differentiate` methods, all of which expose `coord` for coordinate-based numerical operations.

The underlying integration implementation in `Dataset._integrate_one` already treats the supplied value as a coordinate name, validates that the coordinate exists, requires it to be one-dimensional, and then integrates along that coordinate's dimension. The bug was therefore in the `DataArray.integrate` API surface and forwarding variable name, not in the numerical integration logic.

## Files Changed

`repo/xarray/core/dataarray.py`

- Renamed the `DataArray.integrate` argument from `dim` to `coord`.
- Updated the method docstring so the note and parameter documentation refer to `coord`.
- Changed the delegation call to pass `coord` through to `Dataset.integrate`.
- Added a small compatibility wrapper that accepts the previous `dim=` keyword, emits a `FutureWarning`, translates it to `coord=`, and rejects calls that specify both names.

## Assumptions and Alternatives

I assumed existing positional calls such as `da.integrate("x")` must keep working unchanged. I also assumed callers using the old `dim=` keyword should not break immediately, because the issue explicitly raised the question of whether a deprecation cycle was needed and the existing tree contains at least one test helper using `dim=`.

I considered a hard rename that removed `dim=` support entirely. I rejected that because it would make the API stricter but would unnecessarily break existing keyword callers. I also considered exposing `**kwargs` directly in the method signature to catch `dim=`, but rejected that because it would make the public signature less clear. The wrapper keeps the visible signature as `coord` while preserving a deprecated path for the old keyword.
