# FVK Spec

Status: constructed, not machine-checked.

Scope: V1 changes in `repo/xarray/core/common.py` and `repo/xarray/core/variable.py`, specifically `get_chunksizes()` and `Variable.chunksizes`. The public callers covered by this audit are `Dataset.chunks`, `Dataset.chunksizes`, and `DataArray.chunksizes`.

## Intent Spec

1. Accessing `Dataset.chunks` on a lazily opened zarr-backed dataset must be metadata-only. It must not call `Variable.data`, `Variable.values`, `np.asarray`, an indexing wrapper `__array__`, or a backend array `__getitem__`.
2. `Variable.chunksizes` must also be metadata-only, because `get_chunksizes()` delegates to it for chunked variables.
3. Existing public `.chunks` semantics must be preserved: unchunked arrays contribute no chunk entries, while arrays whose underlying data already has chunk metadata contribute dimension-to-chunk mappings.
4. Existing inconsistency behavior must be preserved: if two chunked variables report different chunk tuples for the same dimension, `get_chunksizes()` raises the existing `ValueError`.
5. No public signature, return type, or test-file behavior may be changed.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Accessing chunks on zarr backed xarray seems to load entire array into memory" | `.chunks` access must not materialize backend data. | Encoded in C1, C3. |
| E2 | prompt trace | `get_chunksizes()` called `hasattr(v.data, "chunks")`, then `Variable.data -> values -> np.asarray -> ZarrArrayWrapper.__getitem__`. | The root cause is any chunk metadata path through `v.data`. | Encoded in C1-C3; V1 removes this path. |
| E3 | prompt expectation | "should simply inspect the `encoding` attribute on the underlying DataArrays" | Positive intent is metadata-only inspection rather than data reads. | Encoded as no-load metadata access. Not interpreted as changing `.chunks` to return storage chunks because E4-E5 constrain public semantics. |
| E4 | public docs in source | `Dataset.chunks` docstring says chunks are for the dataset data, "or None if the underlying data is not a dask array." | `.chunks` remains about actual chunked array data, not storage encoding alone. | Encoded in C2-C3. |
| E5 | public tests in source | Backend tests assert `chunks=None` leaves opened variables with `v.chunks is None`; dataset tests assert an unchunked dataset has `data.chunks == {}`. | Unchunked lazy backend arrays must not start reporting zarr storage chunks as dask chunks. | Encoded in C2-C3. |
| E6 | implementation | `ZarrStore.open_store_variable()` records zarr chunks in `encoding["chunks"]` and `encoding["preferred_chunks"]`. | Encoding metadata exists and can inform dask chunking elsewhere, but is not by itself the public `.chunks` return value under E4-E5. | Compatibility note; no V2 source change. |
| E7 | implementation | `Dataset.chunks`, `Dataset.chunksizes`, and `DataArray.chunksizes` all call `get_chunksizes()`. | Fixing `get_chunksizes()` and `Variable.chunksizes` covers the reported caller family. | Encoded in C3-C4. |

## Formal Claims

C1. `Variable.chunks` is metadata-only: for any variable whose `_data` chunk metadata is `C`, reading `chunks` returns `C` or `None` without changing the no-load state.

C2. `Variable.chunksizes` is metadata-only and value-preserving: if `chunks is None`, it returns `{}`; otherwise it returns the mapping produced by zipping `dims` with `chunks`, without changing the no-load state.

C3. `get_chunksizes(variables)` is metadata-only and behavior-preserving: for a finite iterable of variables, it returns the merged dimension-to-chunks mapping over chunked variables, skips unchunked variables, raises the existing inconsistency error on conflicting entries, and never calls data materialization APIs.

C4. Public caller compatibility: `Dataset.chunks`, `Dataset.chunksizes`, and `DataArray.chunksizes` keep their signatures and return-shape contracts because they still delegate to `get_chunksizes()`.

The corresponding abstract K artifacts are `fvk/mini-xarray-chunks.k` and `fvk/xarray-chunks-spec.k`.

## Formal Spec English

The K claims say: calling `chunks`, `chunksizes`, or `getChunksizes` from an unloaded lazy state returns only metadata-derived chunk information and leaves the `loaded` cell false. `NoChunks` variables produce no entries. `SomeChunks` variables produce `zipDimsChunks(dims, chunks)`. `getChunksizes` merges those maps over the variable sequence.

## Adequacy Audit

| Claim | Intent match | Result |
| --- | --- | --- |
| C1 | Matches E1-E2 by proving the basic chunk metadata accessor does not load data. | Pass. |
| C2 | Matches E1-E5 by proving `chunksizes` is metadata-only and preserves unchunked behavior. | Pass. |
| C3 | Matches E1-E5 and E7 by proving dataset/dataarray chunk aggregation does not load data and preserves chunk conflict behavior. | Pass. |
| C4 | Matches E5 and E7 by preserving public call shape. | Pass. |
| Encoding literal from E3 | Reading E3 as "return zarr storage chunks from `.chunks`" would conflict with E4-E5. Reading it as "use metadata rather than data" satisfies the issue without breaking the public contract. | Resolved; no code change. |

## Public Compatibility Audit

No public function signature changed. No virtual dispatch call was given new parameters. No storage format changed. The only changed behavior is that metadata access avoids `Variable.data`; returned mappings and inconsistency errors are intended to remain the same as before for completed executions.
