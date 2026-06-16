# Baseline Notes

## Root Cause

The top-level `xr.where` delegates to `apply_ufunc` without passing a
`keep_attrs` policy, so `apply_ufunc` falls back to dropping attrs. Even when
attrs are requested, the original argument order puts `cond` before `x` and
`y`, which makes `apply_ufunc` consider the condition's attrs first. This is a
poor fit for `where`, because the returned values come from `x` or `y`, and
conditions are commonly produced by comparisons that have already dropped
attrs.

## Changed Files

- `repo/xarray/core/computation.py`: added a `keep_attrs` argument to
  `xr.where`, resolved `None` via the existing global `keep_attrs` option with
  a default of preserving attrs, and routed the underlying ufunc through a small
  helper that accepts `x`, `y`, then `cond`. This lets `apply_ufunc` copy attrs
  from the selected data arguments before falling back to the condition. The
  adjacent docstring was updated for the new parameter and the resulting
  preserved DataArray name.

## Assumptions and Alternatives

- I assumed `xr.where` should behave like the `DataArray.where` and
  `Dataset.where` methods for attrs: preserve attrs by default unless the
  global `keep_attrs` option or an explicit `keep_attrs=False` says otherwise.
- I treated attrs on `x` and `y` as more meaningful than attrs on `cond`,
  because `where` returns selected data values rather than the boolean mask.
- I considered only passing `keep_attrs` through to `apply_ufunc` while keeping
  the original argument order. I rejected that because it would still copy attrs
  from `cond` first, leaving cases like `xr.where(da == 0, -1, da)` without the
  attrs from `da` when the comparison mask has none.
- I did not change comparison/binary-operation attr behavior. That is a broader
  attr-propagation policy issue, and the targeted defect here is the
  `xr.where` wrapper.
- I did not change dtype promotion in `where`. The issue notes dtype changes as
  a separate observation, but the public hints point at attr propagation through
  `apply_ufunc`, and `duck_array_ops.where` already centralizes dtype handling
  for this operation.
