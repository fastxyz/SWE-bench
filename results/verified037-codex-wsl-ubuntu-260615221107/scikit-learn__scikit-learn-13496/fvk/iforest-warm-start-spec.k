requires "mini-iforest-api.k"

module IFOREST-WARM-START-SPEC
  imports MINI-IFOREST-API

  // SPEC-PROVENANCE:
  // - from_prompt: "expose `warm_start` in `IsolationForest.__init__()`,
  //   default `False`" => omitted argument stores false.
  // - from_public_compatibility: existing positional arguments keep their
  //   old field mapping.
  claim [IFOREST-DEFAULT-WARM-START]:
    <k> oldCtor(NE, MS, C, MF, B, NJ, BH, RS, V) => .K </k>
    <state> .Map => iforestState(NE, MS, C, MF, B, NJ, BH, RS, V, false) </state>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "IsolationForest supports incremental addition of new
  //   trees with the `warm_start` parameter of its parent class" => the
  //   public constructor value is propagated to the inherited state.
  claim [IFOREST-EXPLICIT-WARM-START]:
    <k> newCtor(NE, MS, C, MF, B, NJ, BH, RS, V, W) => .K </k>
    <state> .Map => iforestState(NE, MS, C, MF, B, NJ, BH, RS, V, W) </state>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_compatibility: adding an optional parameter must not shift
  //   public positional arguments that existed before the change.
  // - finding_F1: V1 failed this obligation by inserting warm_start before
  //   n_jobs; V2 satisfies it by appending warm_start after verbose.
  claim [IFOREST-POSITIONAL-COMPAT]:
    <k> oldCtor(100, Auto, Legacy, OneFloat, false, 3, New, 0, 1) => .K </k>
    <state> .Map => iforestState(100, Auto, Legacy, OneFloat, false,
                                 3, New, 0, 1, false) </state>
    [all-path]
endmodule
