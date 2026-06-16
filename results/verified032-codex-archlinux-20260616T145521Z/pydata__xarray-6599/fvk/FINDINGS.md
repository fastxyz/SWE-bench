# FVK Findings

Status: constructed, not machine-checked. No tests or project code were run.

## F1 - Resolved Code Bug: Timedelta Conversion Used A Datetime Offset

Input: `xr.polyval(azimuth_time.coords["azimuth_time"], polyfit_coefficients)`
where the coordinate values are `timedelta64[ns]`.

Observed before V1: `_ensure_numeric` sent the timedelta data to
`datetime_to_numeric` with `offset=np.datetime64("1970-01-01")`, producing the
reported dtype-resolution error when subtracting `timedelta64 - datetime64`.

Expected: the timedelta coordinate values should numericize successfully and be
used by Horner evaluation.

Status: resolved by V1. The `x.dtype.kind == "m"` branch now uses
`offset=np.timedelta64(0, "ns")`.

Traces to: E1, E3, E4, PO1, PO4.

## F2 - Scope Finding: Original MCVE Call Form Is Not The Timedelta-Value Contract

Input: `xr.polyval(azimuth_time, polyfit_coefficients)` from the initial issue
snippet, where `azimuth_time.data` is `datetime64` and
`azimuth_time.coords["azimuth_time"]` is `timedelta64`.

Observed under the new algorithm: `polyval` evaluates the `coord` argument's data
values, so this call evaluates datetime values, not the timedelta index
coordinate.

Expected by resolved public hint: pass the actual timedelta coordinate as
`azimuth_time.coords["azimuth_time"]` when those are the desired x values.

Status: no code change. Restoring legacy index-coordinate lookup would contradict
the public hint that the new algorithm uses `coord` values directly.

Traces to: E2, PO7.

## F3 - Scope Finding: Plain NumPy Timedelta Arrays Remain Outside The Public Signature

Input: `xr.polyval(values - values[0], polyfit_coefficients)` where the first
argument is a NumPy array.

Observed in the issue: this call also errors.

Expected by public API: `coord` is a `DataArray` or `Dataset`; the maintainer
hint says this attempt fails because `values` is a NumPy array.

Status: no code change. Broadening `polyval` to array-like inputs is not required
for this issue and would be a larger API change.

Traces to: E8, PO8.

## F4 - Confirmed Design Choice: Timedelta Offset Must Be Zero, Not The Minimum Value

Input family: timedelta coordinate values that do not start at zero, e.g.
`[10 ns, 20 ns]`.

Candidate alternative rejected: call `datetime_to_numeric` for timedeltas with
`offset=None`, which would choose the minimum timedelta as the offset.

Expected: `polyval` should use the same numeric domain as `polyfit`; timedelta
coordinates are raw durations in nanoseconds.

Status: V1 is confirmed. `np.timedelta64(0, "ns")` keeps a value of `10 ns`
numericized as `10`, not `0`.

Traces to: E7, PO1, PO6.

## F5 - Frame Finding: Datetime, Numeric, Dataset, And Missing-Value Behavior Must Not Regress

Inputs: existing datetime coordinates, numeric coordinates, `Dataset` coord
objects, and datetime-like NaT values.

Expected: V1 should only add correct timedelta support; it should preserve the
existing datetime epoch conversion, leave numeric inputs unchanged, keep Dataset
mapping behavior, and preserve NaT-to-NaN conversion through `datetime_to_numeric`.

Status: confirmed by inspection and proof obligations. The separate branches keep
the datetime path unchanged, the `return x` path keeps numeric behavior, Dataset
still maps through `Dataset.map`, and both datetime-like branches use
`datetime_to_numeric`.

Traces to: PO2, PO3, PO5.

## F6 - Honesty Finding: Proof Is Constructed, Not Machine-Checked

Input: the FVK proof artifacts.

Observed: benchmark constraints forbid running `kompile`, `kast`, `kprove`,
tests, or Python code.

Expected: artifacts must record the exact commands and label the result
constructed, not machine-checked.

Status: no code change. Test-removal recommendations are not made.

Traces to: PO9.
