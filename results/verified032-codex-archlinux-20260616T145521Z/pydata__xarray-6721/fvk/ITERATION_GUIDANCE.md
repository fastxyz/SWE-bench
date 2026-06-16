# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not edit the source further for this issue. F-001 is resolved by PO-001 through PO-003. F-002 explains why the audit does not broaden `.chunks` to return zarr storage chunks from `encoding`.

## Recommended Next Tests

Do not modify tests in this task. In a normal development branch, add focused tests for:

- `Dataset.chunks` on a lazy backend-like variable whose array materialization raises if touched.
- `DataArray.chunksizes` on the same kind of lazy variable.
- Existing dask-chunked behavior, including inconsistent chunks along a shared dimension.

## Commands Not Run

The task forbids execution. The following are intentionally recorded only in `fvk/PROOF.md`:

```sh
kompile fvk/mini-xarray-chunks.k --backend haskell
kast --backend haskell fvk/xarray-chunks-spec.k
kprove fvk/xarray-chunks-spec.k
```

## Future Product Question

If xarray wants to expose zarr storage chunks for un-dask-backed lazy arrays, that should be a separately specified API or a separately justified change to `.chunks`. The present issue can be fixed without changing `.chunks` semantics.
