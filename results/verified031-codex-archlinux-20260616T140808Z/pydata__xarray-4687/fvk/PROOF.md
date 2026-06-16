# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Claims Proved In This Model

- WHERE-VALUE: V1 preserves value selection.
- WHERE-KEEP-TRUE: when attrs are kept, data arguments are considered before
  the condition.
- WHERE-KEEP-FALSE: explicit false drops attrs.
- WHERE-KEEP-NONE: `None` resolves through the global option with default true.
- WHERE-EXACT-JOIN: exact alignment policy is unchanged.

## Proof Sketch

1. Symbolically enter `where(cond, x, y, keep_attrs)`.
2. If `keep_attrs is None`, source code rewrites it to
   `_get_keep_attrs(default=True)`. This proves PO-5 against the existing
   option helper.
3. The call to `apply_ufunc` uses `_where_data_first` and argument order
   `(x, y, cond)`.
4. `_where_data_first(x, y, cond)` rewrites in one step to
   `duck_array_ops.where(cond, x, y)`, proving PO-1: selected values are the
   original `cond ? x : y` values.
5. `join="exact"` and `dataset_join="exact"` are unchanged, proving PO-2.
6. `apply_ufunc` maps boolean `keep_attrs=True` to `combine_attrs="override"`.
   With arguments ordered as `x, y, cond`, override picks attrs from the first
   attrs-bearing xarray data argument before the mask, proving PO-3 in the
   abstract model.
7. `apply_ufunc` maps `keep_attrs=False` to `combine_attrs="drop"`, proving
   PO-4.
8. Existing callers using exactly three arguments still match the new optional
   fourth-argument signature, proving PO-6.

## Residual Findings

FVK-F1 remains a real limitation: if attrs were already dropped while building
`cond`, and both `x` and `y` are scalars, `xr.where` has no source object from
which to copy attrs. The public hint identifies this as the separate
comparison-attrs issue, so it does not block the `xr.where` wrapper proof.

FVK-F2 records the compatibility risk of default preservation. The proof does
not erase that risk; it shows the code implements the intent-supported policy
and preserves opt-out behavior.

## Machine-Check Commands

These commands were not run:

```sh
kompile fvk/mini-xarray-where.k --backend haskell
kast --backend haskell fvk/xarray-where-spec.k
kprove fvk/xarray-where-spec.k
```

Expected future machine-check result after the abstract model is accepted:
`#Top`.

## Test Guidance

No tests are removed. If machine-checking later succeeds, point tests for
`keep_attrs=True`, `keep_attrs=False`, and global-option behavior would be
subsumed by the proof, but integration tests over real `DataArray`, `Dataset`,
dask, units, and dtype behavior should remain because the mini-model abstracts
those systems.
