# Iteration Guidance

Status: V1 stands.

## Code Decision

Do not revise `repo/xarray/core/computation.py` in this FVK pass. The V1 source
change discharges PO-1 through PO-6 and PO-8. The only remaining limitation,
FVK-F1, is outside the `xr.where` wrapper because the attrs are already gone
before `where` is called.

## Recommended Future Tests

Do not modify tests in this benchmark task. Future public tests should cover:

- `xr.where(da == 0, -1, da).attrs == da.attrs` for default/global-default
  behavior.
- `xr.where(da == 0, -1, da, keep_attrs=False).attrs == {}`.
- `with xr.set_options(keep_attrs=False): xr.where(...).attrs == {}`.
- `with xr.set_options(keep_attrs=True): xr.where(data == 1, 5, 0).attrs`
  preserves attrs when the comparison result itself kept attrs.
- Dataset attrs and per-variable attrs when `x` or `y` is a `Dataset`.

## Future Non-Goals For This Issue

- Do not change dtype promotion in this patch; `duck_array_ops.where` owns that
  behavior.
- Do not change `DataArray.__eq__` or general binary-operation attr propagation
  in this patch. That is the separate issue identified by the public hint.

## FVK Follow-Up

The `.k` model is intentionally abstract. A stronger later FVK pass could model
more of `apply_ufunc`, `DataArray`, and `Dataset` directly, then run:

```sh
kompile fvk/mini-xarray-where.k --backend haskell
kast --backend haskell fvk/xarray-where-spec.k
kprove fvk/xarray-where-spec.k
```
