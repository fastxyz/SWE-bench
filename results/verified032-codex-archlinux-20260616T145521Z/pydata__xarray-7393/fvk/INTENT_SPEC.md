# Intent Spec

Status: constructed, not machine-checked.

## Public Intent

I1. Creating a MultiIndex through `Dataset.stack` must not change the dtype
reported by the level coordinate values. In the issue example, a coordinate
created from `np.array([0], dtype="i4")` should still expose `int32` after
stacking.

I2. Xarray may rely on pandas to store the underlying `MultiIndex`, but pandas'
materialized level dtype is not the public xarray dtype when xarray already has
the original coordinate dtype.

I3. For an xarray variable backed by a pandas index wrapper, `.values` and
`.dtype` should be consistent for the same coordinate unless an explicit dtype
conversion is requested.

I4. Explicit NumPy array conversion requests remain meaningful: if
`__array__(dtype=...)` is called with a dtype, that requested dtype overrides the
adapter's stored dtype.

I5. The fix should be source-only and must not modify tests.

## Domain

The intended domain is a `PandasMultiIndexingAdapter` created for a named
MultiIndex level by xarray's `PandasMultiIndex.create_variables`, where:

- `level is not None`;
- `adapter.dtype` is the level coordinate dtype xarray recorded from the
  original coordinate variable;
- pandas can materialize the level values; and
- those values are castable to the effective dtype.

The `level is None` branch is in compatibility scope because the same method
handles the aggregate MultiIndex coordinate.

## Required Behavior

B1. If `dtype is None`, `PandasMultiIndexingAdapter.__array__` must use
`self.dtype` as the effective dtype.

B2. If `dtype` is explicitly provided, the result must use that explicit dtype.

B3. For `level is not None`, the resulting NumPy array must contain the pandas
level values cast to the effective dtype.

B4. For the default call in the reported issue, the resulting values dtype must
equal the original coordinate dtype stored in the adapter, not pandas'
promoted materialized dtype.

B5. For `level is None`, behavior should remain delegated to
`PandasIndexingAdapter.__array__`.

