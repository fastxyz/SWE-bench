requires "mini-related-manager.k"

module RELATED-MANAGER-ASYNC-SPEC
  imports MINI-RELATED-MANAGER

  // SPEC-PROVENANCE:
  // - E1/E2: async methods on related managers must call the corresponding
  //   related-manager sync methods rather than queryset proxy methods.
  // - E5: reverse FK sync methods inject the bound instance into the FK.
  claim <k> invokeAsync(reverseFK, O:Op, T:ThroughDefaults)
        => reverseFkEffect(O) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2: async methods on related managers must call the corresponding
  //   related-manager sync methods.
  // - E6/E7: m2m sync methods link created objects and preserve
  //   through_defaults.
  claim <k> invokeAsync(manyToMany, O:Op, T:ThroughDefaults)
        => manyToManyEffect(O, T) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E8: generic related managers have relation-specific sync methods that
  //   populate content type and object id fields.
  claim <k> invokeAsync(genericRel, O:Op, T:ThroughDefaults)
        => genericEffect(O) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E9: normal managers/querysets should keep existing queryset proxy async
  //   behavior; the fix is local to related managers.
  claim <k> invokeAsync(plain, O:Op, T:ThroughDefaults)
        => querysetProxyEffect(O) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E10: the new async wrappers are mutating methods and should carry
  //   alters_data = True.
  claim <k> checkAltersData(M:Manager, O:Op) => true </k>
    requires isRelated(M)
    [all-path]
endmodule

