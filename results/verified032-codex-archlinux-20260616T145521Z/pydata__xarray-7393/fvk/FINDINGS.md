# FVK Findings

Status: constructed, not machine-checked.

## F1: Pre-V1 dtype preservation bug

Classification: code bug, resolved by V1.

Input:

```python
ds = xr.Dataset(coords={"a": np.array([0], dtype="i4")})
ds.stack(b=("a",))["a"].values.dtype
```

Observed before V1: pandas materialized the MultiIndex level values with a
promoted dtype such as `int64`.

Expected from public intent: the stacked level coordinate values expose the
original coordinate dtype, `int32`.

Cause: `PandasMultiIndexingAdapter.__array__` returned
`self.array.get_level_values(self.level).values` directly, bypassing the dtype
stored in the adapter.

Resolution: V1 defaults `dtype` to `self.dtype` and calls `np.asarray(...,
dtype=dtype)` in the level branch. This discharges `PO1`, `PO3`, and `PO4`.

## F2: Producer path already carries the required dtype

Classification: no additional code change needed.

Input: stacked coordinate variables created by `PandasMultiIndex.stack` and
`PandasMultiIndex.create_variables`.

Observed in source: `PandasMultiIndex.stack` records `{k: var.dtype ...}` in
`level_coords_dtype`, and `create_variables` passes that dtype to
`PandasMultiIndexingAdapter`.

Expected: the materialization consumer should use the existing dtype metadata.

Resolution: no producer-path edit is justified. This discharges `PO2` and
supports keeping V1 targeted to `repo/xarray/core/indexing.py`.

## F3: Explicit dtype override must remain supported

Classification: compatibility obligation, resolved by V1.

Input: `np.asarray(adapter, dtype=requested_dtype)` for a named MultiIndex
level.

Expected: the requested dtype overrides `adapter.dtype`.

Audit result: V1 only defaults to `self.dtype` when `dtype is None`; otherwise
it passes the requested dtype through to `np.asarray`. This discharges `PO5`.

## F4: Non-level MultiIndex conversion must remain unchanged

Classification: compatibility obligation, resolved by V1.

Input: `PandasMultiIndexingAdapter` with `level is None`.

Expected: delegate to `PandasIndexingAdapter.__array__`.

Audit result: V1 still calls `super().__array__(dtype)` for `level is None`.
This discharges `PO7`.

## F5: Machine-checking and concrete pandas/NumPy behavior remain outside this run

Classification: proof capability and environment boundary, not a code bug.

Input: real pandas `MultiIndex.get_level_values(...).values` and real NumPy
`np.asarray(..., dtype=...)`.

Expected: future machine checking can validate the formal fragment; runtime
tests can validate integration with actual pandas and NumPy versions.

Audit result: the task forbids tests, Python execution, and K tooling, so the
proof is constructed only. Do not remove tests based on this run. This is
tracked by `PO9`.

