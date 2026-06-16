# Intent Spec

Status: intent-only, derived before accepting candidate behavior as correct.

Target: `xarray.core.computation.where(cond, x, y, keep_attrs=None)`.

## Required Behaviors

1. `xr.where` returns values from `x` where `cond` is true and from `y` where
   `cond` is false, using xarray-style broadcasting and exact alignment.
2. Top-level `xr.where` must provide a way to preserve attrs when called on
   xarray objects with attrs.
3. For attr preservation, attrs from the selected data arguments `x` and `y`
   are semantically more relevant than attrs from `cond`, because `cond` is a
   mask and is often produced by comparisons that drop attrs.
4. `keep_attrs=False` must remain a way to drop attrs.
5. `keep_attrs=None` should respect xarray's global `keep_attrs` option. The
   default policy for this operation is allowed to preserve attrs because the
   issue's expected output and the method-level workaround both expect attrs to
   remain.
6. `DataArray.__eq__` dropping attrs is a separate public issue. `xr.where`
   cannot recover attrs that were already removed from `cond` when both `x` and
   `y` are non-xarray scalars.
7. Dtype promotion is not part of this fix; the issue itself identifies it as
   likely outside xarray's `where` wrapper behavior.

## Domain

Inputs are the existing public domain of `xr.where`: scalar, array, `Variable`,
`DataArray`, or `Dataset` arguments that `apply_ufunc` can align exactly under
the existing `join="exact"` and `dataset_join="exact"` policy.

This spec is partial correctness only. It does not prove termination,
performance, lazy execution, dtype promotion, or the complete implementation of
`apply_ufunc`.
