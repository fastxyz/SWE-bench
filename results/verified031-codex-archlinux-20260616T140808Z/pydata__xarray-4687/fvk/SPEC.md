# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Target

`repo/xarray/core/computation.py`

```python
def where(cond, x, y, keep_attrs=None):
    ...
```

## Public Intent Ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The core entries are:

- E1/E2: top-level `xr.where` dropping attrs is the defect; attrs should be
  preserved or user-controllable.
- E3/E7: `xr.where(da == 0, -1, da).attrs` and the `DataArray.where` workaround
  establish that attrs from the data object should be preserved.
- E4: attrs already dropped by `DataArray.__eq__` are a separate issue.
- E5/E6: the wrapper must pass `keep_attrs` to `apply_ufunc`, and the fix must
  expose choice or respect the global option rather than hard-coding only one
  behavior.
- E8: value semantics remain "return `x` where `cond`, else `y`."

## Contract

For all in-domain scalar, array, `Variable`, `DataArray`, and `Dataset` inputs
accepted by the existing `apply_ufunc` path:

1. Value result:
   `xr.where(cond, x, y, keep_attrs=K)` returns the same selected values as
   `duck_array_ops.where(cond, x, y)`.
2. Alignment:
   dimension and dataset-variable alignment remain exact.
3. Attr result:
   - if `keep_attrs=False`, result attrs are empty;
   - if `keep_attrs=True`, result attrs come from the first xarray object among
     `x` and `y`, falling back to `cond`;
   - if `keep_attrs=None`, `keep_attrs` is resolved through
     `_get_keep_attrs(default=True)`, then one of the two previous cases
     applies.
4. Scope:
   `xr.where` does not repair attrs already lost while constructing `cond`.
   Dtype promotion is delegated to `duck_array_ops.where`.

## Formal Core

The abstract K model is:

- `fvk/mini-xarray-where.k`
- `fvk/xarray-where-spec.k`

Exact commands to machine-check later, not executed here:

```sh
kompile fvk/mini-xarray-where.k --backend haskell
kast --backend haskell fvk/xarray-where-spec.k
kprove fvk/xarray-where-spec.k
```

Expected result after a successful future machine check: `#Top`.
