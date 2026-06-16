# Baseline Notes

## Root cause

`xr.where(..., keep_attrs=True)` needs to keep attrs from `x`, the second public
argument. The existing implementation did this with a callable that always
returned `getattr(x, "attrs", {})`.

That callable is passed through `apply_ufunc` as the general `combine_attrs`
strategy. It is used not only for the output data variable attrs, but also while
merging coordinate variables in `build_output_coords_and_indexes()`. As a
result, coordinate variables such as `time` received the attrs from the data
array `x` instead of retaining coordinate-specific attrs.

## Files changed

- `repo/xarray/core/computation.py`
  - Changed only the `keep_attrs is True` branch of `where`.
  - The branch now calls `apply_ufunc` with `x` as the first labeled argument and
    a small wrapper that still evaluates `duck_array_ops.where(cond, x, y)`.
    This lets the existing `"override"` attrs behavior preserve attrs from `x`
    for data variables and from `x`'s coordinates during coordinate merging.
  - After the call, result attrs are normalized from `x`. This preserves the
    previous scalar behavior where scalar `x` contributes no attrs, and it also
    keeps Dataset data variable attrs aligned with the corresponding variables
    in Dataset `x`.

## Assumptions and alternatives

- I assumed `keep_attrs=True` for `xr.where` should continue to mean "keep attrs
  from `x`", matching the docstring and the `DataArray.where` / `Dataset.where`
  methods.
- I assumed coordinate attrs should be preserved from `x` when `x` supplies the
  coordinate, and otherwise from the next labeled argument participating in the
  coordinate merge. This follows normal `apply_ufunc(..., keep_attrs=True)`
  `"override"` behavior after putting `x` first.
- I considered restoring coordinate attrs after the old callable-based call, but
  rejected that because the callable still applies the wrong attrs during
  coordinate merging and can mutate reused coordinate variables before any
  cleanup.
- I considered changing the general `apply_ufunc` coordinate attrs machinery,
  but rejected that as broader than this issue. The regression is specific to
  the special `xr.where(..., keep_attrs=True)` handling.

Per task constraints, I did not run tests or execute code.
