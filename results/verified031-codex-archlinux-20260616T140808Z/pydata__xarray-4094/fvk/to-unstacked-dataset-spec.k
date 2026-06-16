// Constructed, not machine-checked.
// Abstract claims for DataArray.to_unstacked_dataset after the V2 repair.

requires "mini-xarray-unstack.k"

module TO-UNSTACKED-DATASET-SPEC
  imports MINI-XARRAY-UNSTACK
  imports BOOL
  imports LIST
  imports MAP
  imports K-EQUAL

  syntax Bool ::= noCoord(Map, String) [function]
                | preservesSamples(Map, Arr) [function]
                | missingLevelsDropped(Map) [function]
                | mergeCompatible(Map) [function]

  // SPEC-PROVENANCE:
  // - E7: non-MultiIndex inputs raise ValueError.
  claim
    <k> toUnstackedDataset(A:Arr, DIM:String, VAR:String) => finish(dataset(.Map)) ... </k>
    <out> _ => valueError </out>
    requires notBool isMultiIndex(A, DIM)
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E3/E4/E5: single-level to_stacked_array outputs roundtrip and preserve
  //   sample dimensions, including length-one sample dimensions.
  // - E2: consumed stacked metadata is not merged as conflicting coordinates.
  claim
    <k> toUnstackedDataset(A:Arr, DIM:String, VAR:String) => finish(dataset(OUT:Map)) ... </k>
    <out> _ => ok(dataset(OUT)) </out>
    requires isMultiIndex(A, DIM)
      andBool levelLabels(A, DIM, VAR) =/=K .List
    ensures noCoord(OUT, DIM)
      andBool noCoord(OUT, VAR)
      andBool preservesSamples(OUT, A)
      andBool mergeCompatible(OUT)
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: mixed-dimensional roundtrips keep real stacked levels and remove only
  //   missing-level sentinels.
  claim
    <k> toUnstackedDataset(A:Arr, DIM:String, VAR:String) => finish(dataset(OUT:Map)) ... </k>
    <out> _ => ok(dataset(OUT)) </out>
    requires isMultiIndex(A, DIM)
    ensures missingLevelsDropped(OUT)
      andBool preservesSamples(OUT, A)
      andBool mergeCompatible(OUT)
    [all-path]
endmodule
