requires "mini-xarray.k"

module COARSEN-CONSTRUCT-SPEC
  imports MINI-XARRAY

  // SPEC-PROVENANCE:
  // - from_prompt: "All variables that were coordinates before the coarsen.construct stay as coordinates afterwards."
  //   => every original coordinate name is in the result coordinate-name set.
  // - from_code: the reshape loop processes obj.variables by key and set_coords
  //   updates coordinate membership after asserting those names are variables.
  claim <k> constructV2(ds(VARS, COORDS)) => ds(VARS, RCOORDS) </k>
    requires COORDS subsetSet VARS
    ensures COORDS subsetSet RCOORDS
    [all-path, label(COORD-PRESERVATION-V2)]

  // SPEC-PROVENANCE:
  // - from_code: each processed key is assigned back into reshaped.
  // - from_prompt: coordinate preservation relies on every coordinate name still
  //   being a variable name before set_coords is called.
  claim <k> reshapeAll(ds(VARS, COORDS)) => ds(RVARS, RCOORDS) </k>
    requires COORDS subsetSet VARS
    ensures (VARS subsetSet RVARS)
     andBool (RCOORDS subsetSet RVARS)
    [all-path, label(LOOP-PRESERVES-NAMES)]

  // SPEC-PROVENANCE:
  // - from_prompt example: coordinate "day" is not the coarsened dimension
  //   "time" but must remain a coordinate.
  // - from_baseline: the pre-fix intersection with window_dim drops "day".
  claim <k> constructV1(
              ds(SetItem("T") SetItem("day"), SetItem("day")),
              SetItem("time"))
          => ds(RVARS, RCOORDS) </k>
    ensures notBool ("day" in RCOORDS)
    [all-path, label(PREFIX-COUNTEREXAMPLE)]

  // SPEC-PROVENANCE:
  // - from_code: DataArray._to_temp_dataset uses real coordinates as coord_names
  //   and stores the data under _THIS_ARRAY.
  // - from_compatibility: the audited set(self.obj.coords) excludes _THIS_ARRAY.
  claim <k> constructV2(
              ds(COORDS |Set SetItem("_THIS_ARRAY"), COORDS))
          => ds(RVARS, RCOORDS) </k>
    requires notBool ("_THIS_ARRAY" in COORDS)
    ensures (COORDS subsetSet RCOORDS)
     andBool ("_THIS_ARRAY" in RVARS)
    [all-path, label(DATAARRAY-TEMP-PRESERVATION)]
endmodule
