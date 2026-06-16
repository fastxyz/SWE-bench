# Intent Spec

Status: constructed from public evidence, before accepting candidate behavior as
the specification.

## Required Behavior

I1. `xarray.polyval` evaluates a polynomial at the values supplied by its
`coord` argument.

I2. When those coordinate values are `datetime64`, the existing xarray convention
is to use numeric nanoseconds relative to 1970-01-01. V1 must not regress that
behavior.

I3. When those coordinate values are `timedelta64`, `polyval` must accept them
and evaluate using numeric timedelta duration in nanoseconds. It must not attempt
to subtract a datetime epoch from a timedelta array.

I4. `polyval` remains scoped to `DataArray` and `Dataset` inputs, matching the
public signature in `xarray/core/computation.py`. The NumPy-array workaround in
the issue is outside this public contract.

I5. Missing datetime-like values keep the existing `datetime_to_numeric` behavior:
they become `NaN` in the numericized coordinate.

I6. The fix must not change the public signature, coefficient validation,
degree-label handling, DataArray/Dataset shape behavior, or the Horner
evaluation algorithm except as needed to numericize timedelta coordinates.

## Ambiguity Resolved By Public Hints

The original report's first executable snippet passes a `DataArray` whose data
values are `datetime64` and whose index coordinate is `timedelta64`. The public
hint states that the new `polyval` algorithm uses the values of the `coord`
argument, not the index coordinate. Therefore the in-scope bug is the direct
`DataArray`/coordinate call with `timedelta64` values, not restoring the old
index-coordinate interpretation for that original call.
