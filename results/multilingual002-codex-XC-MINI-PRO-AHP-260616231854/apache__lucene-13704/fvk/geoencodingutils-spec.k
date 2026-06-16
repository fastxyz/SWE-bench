requires "mini-java-geo.k"

module GEOENCODINGUTILS-SPEC
  imports MINI-JAVA-GEO

  // Constructed claim schemas, not machine-checked in this session.
  // SPEC-PROVENANCE:
  // - INT-1/INT-2: narrow north-pole polygon must match its contained encoded point.
  // - INT-3: failure is in the component predicate grid.
  // - INT-4: LatLonDocValuesField stores encoded ints that decode to query coordinates.
  //
  // A full K model would define decode monotonicity over the 32-bit encoded domain and materialize
  // the helper loops from GeoEncodingUtils.java. The markdown proof obligations state those VCs.
endmodule
