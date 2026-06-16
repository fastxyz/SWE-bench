requires "mini-migration-optimizer.k"

module CREATE-MODEL-REDUCE-SPEC
  imports MINI-MIGRATION-OPTIMIZER
  imports MAP
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: "CreateModel + AlterModelManagers can become just
  //   CreateModel" => same-model pair reduces to one CreateModel.
  // - from_code: AlterModelManagers.state_forwards passes self.managers to
  //   alter_model_managers; ProjectState.alter_model_managers replaces the
  //   list => final managers are M1, not M0.
  claim [CREATE-ALTER-MANAGERS-REDUCES]:
    <k> reduceCreate(create(N, F, O, B, M0), alterManagers(N, M1))
      => reduced(create(N, F, O, B, M1) ; .Ops) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the reduction must preserve the behavior of the operation
  //   sequence.
  // - from_code: CreateModel.state_forwards installs F/O/B/M0, then
  //   AlterModelManagers replaces managers with M1.
  claim [TWO-STEP-STATE]:
    <k> applyAll(create(N, F, O, B, M0) ; alterManagers(N, M1) ; .Ops)
      => .K ... </k>
    <state> S:Map => S [N <- modelSpec(F, O, B, M1)] </state>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the optimized one-operation list must be equivalent to the
  //   original pair.
  claim [ONE-STEP-STATE]:
    <k> applyAll(create(N, F, O, B, M1) ; .Ops)
      => .K ... </k>
    <state> S:Map => S [N <- modelSpec(F, O, B, M1)] </state>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: existing reductions compare normalized model names before
  //   same-model absorption.
  claim [DIFFERENT-MODEL-NOT-ABSORBED]:
    <k> reduceCreate(create(N1, F, O, B, M0), alterManagers(N2, M1))
      => canReduceThrough ... </k>
    requires N1 =/=String N2
    [all-path]
endmodule
