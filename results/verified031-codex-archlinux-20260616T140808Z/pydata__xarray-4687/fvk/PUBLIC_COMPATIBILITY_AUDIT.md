# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Symbol

`xarray.core.computation.where`, re-exported as `xr.where`.

V1 changed:

```python
def where(cond, x, y)
```

to:

```python
def where(cond, x, y, keep_attrs=None)
```

## Callsite Audit

Public in-repository callsites found by text search use the existing
three-argument form. Adding an optional fourth argument preserves these calls.
No subclass override or virtual dispatch target exists for this top-level
function.

## Metadata Compatibility

The default metadata behavior changes for in-domain calls where `x` or `y` is
an xarray object with attrs and the global `keep_attrs` option is `"default"`:
V1 preserves attrs. This is the intended issue fix for `xr.where(da == 0, -1,
da)`, but it is a compatibility risk called out in FVK-F2. Users can request
legacy drop behavior with `keep_attrs=False` or `xr.set_options(keep_attrs=False)`.

## Data/Alignment Compatibility

The wrapper still uses `join="exact"`, `dataset_join="exact"`, and
`dask="allowed"`. The helper only reorders the inputs seen by `apply_ufunc` so
attrs are selected from data arguments first; it calls
`duck_array_ops.where(cond, x, y)` and therefore preserves value selection.

Verdict: no unhandled public callsite or override incompatibility was found.
