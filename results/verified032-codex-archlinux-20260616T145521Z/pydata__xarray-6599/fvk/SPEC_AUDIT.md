# Spec Audit

Status: constructed, not machine-checked.

| Formal clause | Intent entries | Result | Notes |
| --- | --- | --- | --- |
| C1 | I3, E1, E3, E4, E7 | Pass | This is the core bug fix: timedelta values are durations from zero, not datetimes relative to 1970. |
| C2 | I2, E6 | Pass | Keeps the pre-existing datetime convention; no V2 change is justified here. |
| C3 | I6, E5 | Pass | Non-datetime-like coordinate values remain unchanged by `_ensure_numeric`. |
| C4 | I5 | Pass | Follows existing `datetime_to_numeric` missing-value behavior. |
| C5 | I1, I6, E5 | Pass | Matches the public `polyval` docstring and current Horner algorithm. |
| C6 | FVK honesty gate | Pass with limitation | The proof is partial and model-based; exact K commands are recorded but not run. |

## Ambiguities

A1. Original MCVE call form: The issue's first snippet used the whole
`azimuth_time` `DataArray`, whose data are `datetime64`. Public hints clarify
that the new contract uses `coord` values directly and that the direct
`azimuth_time.coords["azimuth_time"]` call should work. The formal spec therefore
does not require restoring old index-coordinate lookup for the original call.

A2. Plain NumPy array argument: The issue records an error for
`xr.polyval(values - values[0], coeffs)`, but the maintainer note says that
attempt fails because `values` is a NumPy array. The public signature supports
`DataArray` and `Dataset`; this is out of scope for the fix.
