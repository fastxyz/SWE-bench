# Public Evidence Ledger

E1. Source: prompt / issue title.
Quote: "`polyval` with timedelta64 coordinates produces wrong results"
Obligation: `polyval` must support timedelta coordinate values, not raise during
numeric conversion and not feed epoch datetimes into a timedelta subtraction.
Status: encoded by PO1 and claim `ensureNumeric(timedelta64, ...)`.

E2. Source: prompt / issue hint.
Quote: "the new polyval algorithm uses the values of the `coord` argument and
not the index coordinate"
Obligation: do not restore legacy index-coordinate lookup for a `DataArray` whose
data values are datetime; direct timedelta coordinate values are the evaluated x
values.
Status: encoded as scope and compatibility condition; see F2.

E3. Source: prompt / maintainer hint.
Quote: "`azimuth_time.coords[\"azimuth_time\"]` ... should work, so this is a bug"
Obligation: `DataArray` coordinate objects with dtype kind `m` are in domain for
`polyval`.
Status: encoded by PO1, PO4, and claims in `polyval-spec.k`.

E4. Source: prompt / traceback.
Quote: "ufunc 'subtract' cannot use operands with types dtype('<m8[ns]') and
dtype('<M8[D]')"
Obligation: the fix must avoid subtracting a `datetime64` offset from
`timedelta64` data.
Status: encoded by PO1; resolved by `offset=np.timedelta64(0, "ns")`.

E5. Source: public API docstring in `polyval`.
Quote: "Values at which to evaluate the polynomial."
Obligation: the numericized `coord` data, not coordinate labels from another
object, are the x values supplied to Horner evaluation.
Status: encoded by PO4.

E6. Source: source code in `get_clean_interp_index`.
Quote: "Numerical datetime values are defined with respect to 1970-01-01T00:00:00
in units of nanoseconds"
Obligation: preserve epoch-nanosecond behavior for datetime64 values.
Status: encoded by PO2.

E7. Source: source code in `get_clean_interp_index` and `Dataset.polyfit`.
Quote: `index = index.values.astype(np.float64)` after the datetime special case.
Obligation: timedelta indexes used by `polyfit` are represented as raw numeric
timedelta values, so `polyval` should use duration since zero for timedeltas.
Status: encoded by PO1 and PO6.

E8. Source: source code public signature.
Quote: overloads accept `DataArray` and `Dataset`, not plain NumPy arrays.
Obligation: no requirement to broaden this fix to `xr.polyval(values -
values[0], coeffs)`.
Status: encoded by F3.
