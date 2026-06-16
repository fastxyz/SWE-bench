requires "mini-autodoc-fieldlist.k"

module AUTODOC-TYPEHINTS-SPEC
  imports MINI-AUTODOC-FIELDLIST
  imports BOOL
  imports STRING

  // SPEC-PROVENANCE:
  // - E-1/E-3: documented-description mode adds return type only for documented returns.
  // - E-4/E-6/E-7: `returns` and `return` are valid aliases; Napoleon emits `returns`.
  // - from_code: V1 records both aliases as canonical `return` description.
  claim
    <k> augmentReturn(FS:Fields, true, ANN:String)
      => addRtype(ANN)
    </k>
    requires hasReturnDescription(FS) andBool notBool hasReturnType(FS)
    [all-path]

  // SPEC-PROVENANCE:
  // - E-4: the issue's failing spelling is `returns`.
  // - PO-2/PO-3: `returns` must trigger the same append condition as `return`.
  claim
    <k> augmentReturn(returnsField ; FS:Fields, true, ANN:String)
      => addRtype(ANN)
    </k>
    requires notBool hasReturnType(FS)
    [all-path]

  // SPEC-PROVENANCE:
  // - E-9: existing public behavior for `return` must be preserved.
  claim
    <k> augmentReturn(returnField ; FS:Fields, true, ANN:String)
      => addRtype(ANN)
    </k>
    requires notBool hasReturnType(FS)
    [all-path]

  // SPEC-PROVENANCE:
  // - I-5: existing return type documentation suppresses duplicate insertion.
  claim
    <k> augmentReturn(rtypeField ; FS:Fields, true, ANN:String)
      => noRtype
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - I-6: documented-description mode does not add return type without a return description.
  claim
    <k> augmentReturn(FS:Fields, true, ANN:String)
      => noRtype
    </k>
    requires notBool hasReturnDescription(FS)
    [all-path]

  // SPEC-PROVENANCE:
  // - I-1: no annotation means there is no return type value to inject.
  claim
    <k> augmentReturn(FS:Fields, false, ANN:String)
      => noRtype
    </k>
    [all-path]
endmodule
