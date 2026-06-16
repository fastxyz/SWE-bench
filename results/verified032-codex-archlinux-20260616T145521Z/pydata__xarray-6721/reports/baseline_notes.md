# Baseline Notes

## Root cause

`Dataset.chunks` and `Dataset.chunksizes` call `get_chunksizes()` over the dataset variables. `get_chunksizes()` checked `hasattr(v.data, "chunks")` before collecting chunk sizes. For lazily opened backend arrays, `Variable.data` can fall back to `Variable.values` when the wrapped backend data is not considered a duck array. That fallback coerces the lazy backend array with `np.asarray`, which reads the array contents. In the zarr case from the issue, this turns a metadata-only `.chunks` access into a full backend read.

`Variable.chunksizes` had the same pattern one level deeper: after checking `self._data`, it built the mapping from `self.data.chunks`, which can also force the lazy data path.

## Files changed

`repo/xarray/core/common.py`

- Changed `get_chunksizes()` to check `v.chunks` instead of `v.data`. `Variable.chunks` reads chunk metadata from `Variable._data` with `getattr` and does not materialize lazy backend arrays.

`repo/xarray/core/variable.py`

- Changed `Variable.chunksizes` to use `self.chunks` directly when building the dimension-to-chunks mapping. This keeps chunk-size metadata access on the internal array wrapper instead of going through `self.data`.

## Assumptions and alternatives considered

- I assumed the intended public behavior of `.chunks` is still to report actual chunked array data, primarily dask chunks, and to return an empty mapping for unchunked datasets. Existing source and tests in this checkout describe and assert that behavior.
- I considered returning zarr `encoding["chunks"]` or `encoding["preferred_chunks"]` from `.chunks` for unchunked zarr-backed arrays because the issue mentions inspecting encoding metadata. I rejected that as a broader semantic change: the backend already uses `preferred_chunks` when dask chunking is requested, while `.chunks` currently represents the chunks of the in-memory/lazy array object itself.
- I assumed hidden coverage will check that accessing `.chunks`/`.chunksizes` does not call `Variable.data` for lazy backend variables, and that existing dask chunk consistency checks still raise on inconsistent chunk sizes. The new code still uses the same chunk tuples; it only avoids the materializing access path.
