# Baseline Notes

## Root cause

`Dataset.stack` records the original dtype for each level coordinate in
`PandasMultiIndex.level_coords_dtype`, and `create_variables` passes that dtype
to `PandasMultiIndexingAdapter`. However, when a level coordinate was converted
to a NumPy array, `PandasMultiIndexingAdapter.__array__` returned
`self.array.get_level_values(self.level).values` directly.

For integer MultiIndex levels, pandas may materialize those values with a
promoted dtype such as `int64`. Because the adapter bypassed the stored xarray
dtype during `__array__`, `.values.dtype` could disagree with the coordinate's
recorded dtype, e.g. an original `int32` coordinate becoming `int64` after
stacking.

## Files changed

`repo/xarray/core/indexing.py`

Updated `PandasMultiIndexingAdapter.__array__` so that, when no dtype is
explicitly requested, it defaults to `self.dtype`, matching
`PandasIndexingAdapter.__array__`. For MultiIndex level coordinates, it now
materializes the pandas level values through `np.asarray(..., dtype=dtype)`,
restoring the dtype already tracked by xarray.

## Assumptions and alternatives

I assumed the intended behavior is to preserve xarray's existing level
coordinate dtype metadata when exposing `.values`, not to change how pandas
constructs or stores the underlying `MultiIndex`.

I considered changing the stack construction path in `PandasMultiIndex.stack`,
but that code already records the original dtype in `level_coords_dtype`, so the
problem is not missing metadata.

I also considered updating `PandasMultiIndex.create_variables`, but it already
passes each level's recorded dtype to `PandasMultiIndexingAdapter`. The mismatch
only appears when the adapter converts a level to a NumPy array.

I rejected changing tests because this benchmark requires the fixed suite to
remain hidden and source-only changes.
