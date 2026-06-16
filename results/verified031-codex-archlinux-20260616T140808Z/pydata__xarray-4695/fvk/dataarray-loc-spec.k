requires "mini-python-loc.k"

module DATAARRAY-LOC-SPEC
  imports MINI-PYTHON-LOC
  imports MAP
  imports STRING
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "The name of the dimension should be irrelevant." =>
  //   every key in an explicit .loc mapping remains an indexer key.
  // - from_docs: "da.loc[dict(space='IA')]" => dict .loc keys are indexers.
  // - from_code: V2 uses self.data_array.sel(key).
  claim [LOC-GENERIC]:
    <k> locGet(M:Map) => dispatched(M, exact) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "D2.loc[dict(dim1='x', method='a')]" should work like D1.
  // - conflicts: pre-fix traceback routed "a" to invalid fill method.
  claim [LOC-METHOD-CONCRETE]:
    <k> locGet("dim1" |-> "x" "method" |-> "a")
     => dispatched("dim1" |-> "x" "method" |-> "a", exact)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: dimension names are irrelevant.
  // - from_code: internal helpers build {dim: value} for dimension selection.
  claim [HELPER-METHOD-CONCRETE]:
    <k> helperSelect("method", "a")
     => dispatched("method" |-> "a", exact)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: dimension names are data, not reserved parameters.
  // - from_code: V2 helper calls use obj.sel({dim: value}).
  claim [HELPER-GENERIC]:
    <k> helperSelect(D:String, V:String)
     => dispatched(D |-> V, exact)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_traceback: "Invalid fill method" after self.data_array.sel(**key).
  // - diagnostic only: this localizes the legacy bug, not intended behavior.
  claim [LEGACY-METHOD-COUNTEREXAMPLE]:
    <k> legacyLocGet("dim1" |-> "x" "method" |-> "a")
     => invalidFillMethod("a")
    </k>
    [all-path]
endmodule
