# Intent Spec

Status: constructed for audit; no tests, Python, or K tooling were run.

## Scope

The audited unit is `xarray.core.variable.as_compatible_data`, plus the two
public paths in the issue that depend on it:

- `Variable.__setitem__` when assigning a scalar object into an object-dtype
  array.
- `DataArray(..., dims=[])` construction for scalar object data.

## Intent-Derived Obligations

I1. Arbitrary Python objects that expose a `.values` attribute are valid scalar
payloads for object-dtype xarray data. They must be preserved as the object, not
replaced by their `.values` attribute.

I2. Scalar assignment through `DataArray.loc[...] = value` must preserve such
objects when the indexed destination is scalar/non-broadcasted.

I3. Scalar `DataArray(value, dims=[])` construction must preserve such objects
instead of coercing to `value.values`.

I4. The fix must replace the generic `.values` probe with explicit type checks
for containers that xarray intentionally unwraps.

I5. Existing intentional unwrapping for known self-described containers must be
preserved. Public evidence names xarray `DataArray`/`Variable` and pandas
`Series`/`DataFrame`; this repository also has explicit pandas `Panel` support
in `DataArray` construction.

I6. Existing special handling for `Variable`, `pandas.Index`,
`PandasIndexAdapter`, `LazilyOuterIndexedArray`, dask/cupy arrays, masked
arrays, datetimes, timedeltas, and NEP-18 duck arrays is outside the reported
bug and should not be changed.

I7. No public API signature, return type family, or assignment/indexing protocol
should change except the intended object preservation for arbitrary `.values`
objects.

## Default-Domain Assumptions

D1. NumPy conversion of an arbitrary Python object that is not a recognized
array container yields a zero-dimensional object array containing that object.

D2. Pandas object conversion in `_possibly_convert_objects` preserves arbitrary
non-datetime objects as object payloads.

D3. The FVK proof is partial correctness only: it reasons about the result if
the audited helper path returns. It does not prove termination of NumPy/pandas
library internals.
