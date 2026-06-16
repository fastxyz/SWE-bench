// Constructed, not machine-checked.
// Exact commands to machine-check later:
//   kompile fvk/mini-xarray-chunks.k --backend haskell
//   kast --backend haskell fvk/xarray-chunks-spec.k
//   kprove fvk/xarray-chunks-spec.k

requires "mini-xarray-chunks.k"

module XARRAY-CHUNKS-SPEC
  imports MINI-XARRAY-CHUNKS
  imports K-EQUAL
  imports MAP-SYMBOLIC

  // SPEC-PROVENANCE:
  // - from_prompt: "Accessing chunks on zarr backed xarray seems to load entire array into memory"
  //   => accessing chunk metadata must preserve the no-load state.
  // - from_trace: get_chunksizes previously evaluated hasattr(v.data, "chunks"),
  //   which entered Variable.data -> values -> np.asarray -> backend reads.
  // - from_code: V1 Variable.chunks reads getattr(self._data, "chunks", None).
  claim
    <k> chunks(Var(DIMS, C, false)) => C </k>
    <loaded> false => false </loaded>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: chunk-size access must be metadata-only.
  // - from_docs_tests: unchunked data reports no dask chunks.
  // - from_code: V1 Variable.chunksizes uses self.chunks, not self.data.
  claim
    <k> chunksizes(Var(DIMS, NoChunks, false)) => .Map </k>
    <loaded> false => false </loaded>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_tests: chunked variables expose a dimension-to-chunks mapping.
  // - from_code: V1 Variable.chunksizes returns Frozen(zip(self.dims, chunks)).
  claim
    <k> chunksizes(Var(DIMS, SomeChunks(CS), false)) => zipDimsChunks(DIMS, CS) </k>
    <loaded> false => false </loaded>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: Dataset.chunks calls get_chunksizes and must not load data.
  // - from_code: V1 get_chunksizes uses v.chunks/v.chunksizes, never v.data.
  // - from_docs_tests: nonchunked variables contribute no entries; chunked
  //   variables are merged subject to the existing consistency check.
  claim
    <k> getChunksizes(VARS) => getChunksizesValue(VARS) </k>
    <loaded> false => false </loaded>
    [all-path]
endmodule
