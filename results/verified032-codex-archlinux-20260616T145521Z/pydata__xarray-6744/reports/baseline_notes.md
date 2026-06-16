# Baseline Notes

## Root cause

`DataArrayRolling.__iter__` always built right-aligned window slices. It computed
`stops` as `1..N`, `starts` as `stops - window`, and only clipped starts at the
left edge. That matches `center=False`, but it ignores `self.center`, so manual
iteration over `da.rolling(..., center=True)` produced the same windows as a
right-aligned rolling object.

The normal rolling reductions do honor `center=True` through
`Variable.rolling_window`, which pads `window // 2` values before the data and
the remaining padding after it. For an iterator over real slices, the equivalent
behavior is to shift the right-aligned slice bounds by `(window - 1) // 2` and
clip both ends to the original array bounds.

## Files changed

- `repo/xarray/core/rolling.py`: updated `DataArrayRolling.__iter__` to include a
  centered offset when `self.center[0]` is true, clip `starts` and `stops` to the
  valid range, and reuse the rolling dimension name locally. This makes manual
  iteration produce windows whose reductions align with centered rolling
  reductions while preserving the existing right-aligned behavior when
  `center` is false or `None`.

## Assumptions and rejected alternatives

- I assumed the iterator should continue yielding slices of the original
  `DataArray`, not padded fixed-length arrays. Existing iterator behavior already
  yields shorter edge windows for right-aligned rolling, and applies
  `min_periods` by masking those windows.
- I matched the centering convention used by `Variable.rolling_window`, including
  even window sizes. For even windows, this means the iterator shifts by
  `(window - 1) // 2`, not `window // 2`.
- I considered changing iteration to call `construct()` internally, but rejected
  that because it would introduce padded temporary window arrays and a larger
  behavioral/performance change. Adjusting the slice bounds directly is the
  minimal fix for the reported issue.
- I did not modify tests because the task requires the hidden fixed test suite
  to remain unchanged.
