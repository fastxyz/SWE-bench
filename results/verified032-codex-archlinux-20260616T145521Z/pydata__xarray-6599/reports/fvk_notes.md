# FVK Notes

The FVK audit confirms V1 and does not require further production-code edits.

Decision D1: keep the V1 timedelta branch unchanged. Finding F1 identifies the
bug as subtracting a datetime offset from timedelta data, and PO1 requires
timedelta numericization with `offset=np.timedelta64(0, "ns")`. V1 satisfies that
obligation at `repo/xarray/core/computation.py:1944-1951`.

Decision D2: keep the zero timedelta offset rather than using
`datetime_to_numeric(..., offset=None)`. Finding F4 and PO6 show that `offset=None`
would convert relative to the minimum coordinate, which would not match
`polyfit`'s raw timedelta numeric domain for coordinates that start away from
zero.

Decision D3: do not restore legacy index-coordinate lookup for
`xr.polyval(azimuth_time, polyfit_coefficients)`. Finding F2 and PO7 trace this
to the public hint that the new algorithm uses `coord` argument values directly.
The in-scope repair is the direct timedelta coordinate call,
`azimuth_time.coords["azimuth_time"]`.

Decision D4: do not broaden `polyval` to accept plain NumPy arrays. Finding F3
and PO8 identify the NumPy workaround as outside the public `DataArray`/`Dataset`
signature.

Decision D5: no frame changes are needed. Finding F5 and PO2-PO5 confirm that V1
preserves datetime epoch conversion, numeric pass-through, Dataset mapping, and
NaT-to-NaN handling while adding the missing timedelta path.

The FVK artifacts are constructed, not machine-checked. Finding F6 and PO9 record
that no tests, Python code, `kompile`, `kast`, or `kprove` commands were run in
this benchmark session.
