# Iteration Guidance

## Code decision

V1's semantic fix stands. The FVK proof obligations support keeping the two
semantic source changes:

- `Variable.quantile` accepts `keep_attrs` and applies it to result attrs
  (PO-1 through PO-3).
- `Dataset.quantile` resolves and passes `keep_attrs` to each variable quantile
  call (PO-4 through PO-6).

The audit found one non-semantic improvement: the `DataArray.quantile` docstring
described copying "dataset" attrs. That mismatched the intent and xarray's
storage model, so V2 changes it to "array's attributes" (F3, PO-12).

## Recommended tests for a later normal development pass

Do not edit tests in this benchmark task. A later test-authoring pass should add
or check public tests for:

- `DataArray.quantile(..., keep_attrs=True)` preserves attrs.
- `DataArray.quantile(..., keep_attrs=False)` drops attrs.
- `Variable.quantile(..., keep_attrs=True)` preserves attrs.
- `Dataset.quantile(..., keep_attrs=True)` preserves data variable attrs and
  dataset attrs.
- `keep_attrs=None` follows `set_options(keep_attrs=True/False)`.

## Machine-checking guidance

The FVK proof is constructed, not machine-checked. To validate the formal core
outside this no-execution environment, run:

```sh
cd fvk
kompile mini-xarray.k --backend haskell
kast --backend haskell quantile-attrs-spec.k
kprove quantile-attrs-spec.k
```

If K rejects syntax in the mini model, repair the model syntax without changing
the source patch unless the repaired proof produces a new finding.

## No further source changes recommended

No open finding justifies changing numeric quantile behavior, dask error
behavior, dimension handling, groupby dispatch, or coordinate/index behavior.
Those paths are framed by PO-8 and PO-9 and should remain untouched.
