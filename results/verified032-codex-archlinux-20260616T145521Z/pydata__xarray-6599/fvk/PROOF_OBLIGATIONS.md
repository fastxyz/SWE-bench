# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Timedelta Numericization

For any `DataArray` variable `x` with `x.dtype.kind == "m"`, `_ensure_numeric`
returns `x.copy(data=datetime_to_numeric(x.data, offset=np.timedelta64(0, "ns"),
datetime_unit="ns"))`.

The resulting numeric value for a non-missing element `t` is `t / 1 ns`, i.e. the
duration in nanoseconds from zero.

Findings: F1, F4.

## PO2 - Datetime Numericization Frame

For any `DataArray` variable `x` with `x.dtype.kind == "M"`, `_ensure_numeric`
continues to use `offset=np.datetime64("1970-01-01")` and
`datetime_unit="ns"`.

Findings: F5.

## PO3 - Non-Datetime-Like Frame

For any `DataArray` variable whose dtype kind is neither `"m"` nor `"M"`,
`_ensure_numeric` returns the original object from `to_floatable` without
changing its data.

Findings: F5.

## PO4 - Polynomial Evaluation After Numericization

After `_ensure_numeric`, `polyval` evaluates coefficients with Horner's method:

1. Fill absent degree labels from `0..max_deg` with zero.
2. Initialize `res` with the coefficient at `max_deg` plus `zeros_like(coord)`.
3. For each lower degree `deg`, update `res = res * coord + coeff[deg]`.
4. Final result equals `sum(coeff[d] * coord ** d for d in 0..max_deg)`.

Findings: F1.

## PO5 - Structure And Missing-Value Frame

The conversion preserves xarray structure through `copy(data=...)` for
`DataArray` and `Dataset.map(to_floatable)` for `Dataset`. Missing datetime-like
values remain governed by `datetime_to_numeric`, which maps NaT to NaN.

Findings: F5.

## PO6 - Polyfit/Polyval Domain Alignment

Timedelta values used by `polyval` must align with `polyfit`'s numeric x-domain:
raw timedelta duration in nanoseconds, not duration relative to the coordinate
minimum.

Findings: F4.

## PO7 - New Algorithm Scope

`polyval` evaluates `coord` argument values directly. It is not obligated to use
a `DataArray`'s index coordinate when the `DataArray`'s own data are datetime
values.

Findings: F2.

## PO8 - Public Signature Scope

The fix applies to the public `DataArray`/`Dataset` contract. Plain NumPy arrays
are not brought into scope by this issue.

Findings: F3.

## PO9 - FVK Honesty Gate

The proof artifacts must remain labeled as constructed, not machine-checked, and
must not justify deleting tests unless the emitted commands are run and return
success.

Findings: F6.
