// Constructed, not machine-checked.
requires "mini-xarray.k"

module QUANTILE-ATTRS-SPEC
  imports MINI-XARRAY
  imports MAP
  imports BOOL

  // SPEC-PROVENANCE:
  // - E5: public hint says Variable.quantile should have keep_attrs.
  // - E1/E2: DataArray.quantile keep_attrs=True must preserve attrs.
  claim [VQ-KEEP-TRUE]:
    <k> variableQuantile(var(DIMS:Dims, DATA:Data, ATTRS:Map),
                         Q:Q, DIM:Dim, INTERP:Interp, true)
      => var(quantileDims(DIMS, Q, DIM),
             quantileData(DATA, Q, DIM, INTERP),
             ATTRS) </k>
    <globalKeep> G:Bool </globalKeep>
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: keep_attrs false/default-false drops attrs in existing xarray reductions.
  claim [VQ-KEEP-FALSE]:
    <k> variableQuantile(var(DIMS:Dims, DATA:Data, ATTRS:Map),
                         Q:Q, DIM:Dim, INTERP:Interp, false)
      => var(quantileDims(DIMS, Q, DIM),
             quantileData(DATA, Q, DIM, INTERP),
             .Map) </k>
    <globalKeep> G:Bool </globalKeep>
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: keep_attrs=None resolves through the global option with default false.
  claim [VQ-KEEP-DEFAULT-TRUE]:
    <k> variableQuantile(var(DIMS:Dims, DATA:Data, ATTRS:Map),
                         Q:Q, DIM:Dim, INTERP:Interp, default)
      => var(quantileDims(DIMS, Q, DIM),
             quantileData(DATA, Q, DIM, INTERP),
             ATTRS) </k>
    <globalKeep> true </globalKeep>
    [all-path]

  claim [VQ-KEEP-DEFAULT-FALSE]:
    <k> variableQuantile(var(DIMS:Dims, DATA:Data, ATTRS:Map),
                         Q:Q, DIM:Dim, INTERP:Interp, default)
      => var(quantileDims(DIMS, Q, DIM),
             quantileData(DATA, Q, DIM, INTERP),
             .Map) </k>
    <globalKeep> false </globalKeep>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4: DataArray.quantile uses a temporary dataset containing the original variable.
  // - E8: Dataset reductions resolve keep_attrs and pass it into variable reductions.
  claim [DATASET-PASS-KEEP]:
    <k> datasetQuantile(dataset("x" |-> var(DIMS:Dims, DATA:Data, ATTRS:Map),
                                COORDS:Map,
                                DATTRS:Map),
                        Q:Q, DIM:Dim, INTERP:Interp, true)
      => dataset("x" |-> var(quantileDims(DIMS, Q, DIM),
                             quantileData(DATA, Q, DIM, INTERP),
                             ATTRS),
                 COORDS,
                 DATTRS) </k>
    <globalKeep> G:Bool </globalKeep>
    [all-path]

  claim [DATASET-PASS-DROP]:
    <k> datasetQuantile(dataset("x" |-> var(DIMS:Dims, DATA:Data, ATTRS:Map),
                                COORDS:Map,
                                DATTRS:Map),
                        Q:Q, DIM:Dim, INTERP:Interp, false)
      => dataset("x" |-> var(quantileDims(DIMS, Q, DIM),
                             quantileData(DATA, Q, DIM, INTERP),
                             .Map),
                 COORDS,
                 .Map) </k>
    <globalKeep> G:Bool </globalKeep>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2: the reported DataArray example must return the original attrs.
  // - E6: DataArray attrs are variable attrs.
  claim [DA-KEEP-TRUE]:
    <k> dataArrayQuantile(dataarray(var(DIMS:Dims, DATA:Data, ATTRS:Map),
                                    COORDS:Map),
                          Q:Q, DIM:Dim, INTERP:Interp, true)
      => dataarray(var(quantileDims(DIMS, Q, DIM),
                       quantileData(DATA, Q, DIM, INTERP),
                       ATTRS),
                   COORDS) </k>
    <globalKeep> G:Bool </globalKeep>
    [all-path]

  claim [DA-KEEP-FALSE]:
    <k> dataArrayQuantile(dataarray(var(DIMS:Dims, DATA:Data, ATTRS:Map),
                                    COORDS:Map),
                          Q:Q, DIM:Dim, INTERP:Interp, false)
      => dataarray(var(quantileDims(DIMS, Q, DIM),
                       quantileData(DATA, Q, DIM, INTERP),
                       .Map),
                   COORDS) </k>
    <globalKeep> G:Bool </globalKeep>
    [all-path]
endmodule
