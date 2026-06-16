# Baseline Notes

## Root cause

`xr.where(..., keep_attrs=True)` rewrote `keep_attrs` to a callable that always returned `attrs[1]`, assuming that the internal list of attrs passed to `merge_attrs` had one entry for `cond` and one entry for `x`. That assumption is false when `x` is a raw scalar, because `apply_ufunc` only collects attrs from xarray-like inputs. For `xr.where(DataArray_condition, 1, 0)`, the attrs list can contain only the condition's attrs, so `attrs[1]` raises `IndexError`.

## Files changed

`repo/xarray/core/computation.py`

Changed the `where` helper's `keep_attrs=True` branch so it no longer relies on a fixed index in the attrs list. It now collects the attrs dictionaries associated with the original `x` argument and returns a matching attrs dictionary when `x` participates in a merge; otherwise it returns an empty attrs dictionary. This preserves the documented behavior of keeping attrs from the second argument when they exist, while treating scalar `x` as having no attrs.

## Assumptions and alternatives

I assumed that `keep_attrs=True` for top-level `xr.where` should mean "keep attrs from `x`" consistently, including the scalar case where `x` has no attrs. I also assumed scalar `x` should not cause attrs from `cond` or `y` to be used as a fallback.

I considered the smaller change of replacing `attrs[1]` with `attrs[1] if len(attrs) > 1 else {}`. I rejected it because it still depends on positional attrs and can preserve attrs from `y` when `x` is scalar but `y` is an xarray object.

I considered changing `apply_ufunc` or `merge_attrs` to account for scalar arguments. I rejected that as too broad for this issue because the incorrect assumption is local to `xr.where`'s custom `keep_attrs=True` handling.

No tests or code were run, per the task instructions.
