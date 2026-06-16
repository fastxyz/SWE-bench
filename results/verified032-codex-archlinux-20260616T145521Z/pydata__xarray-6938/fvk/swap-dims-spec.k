requires "mini-python-swapdims.k"

module SWAP-DIMS-SPEC
  imports MINI-PYTHON-SWAPDIMS

  // SPEC-PROVENANCE:
  // - from_prompt: "I expected it not to modify the original object." => input variable dims must be preserved.
  // - from_prompt: "`ds2['lev']` now has dimension 'lev'" => existing IndexVariable promotion is the failing case.
  // - from_code: IndexVariable.to_index_variable() returns self; copy(deep=False) returns a distinct variable object.
  claim <k> swapDimsPromoteV1(V, NEW) => . ... </k>
        <heap> V |-> var(index, OLD, D, A, E) => V |-> var(index, OLD, D, A, E) H </heap>
        <result> none => R </result>
        <fresh> N => N +Int 1 </fresh>
    requires V =/=Int N
     ensures R =/=Int V
      andBool H [ R ] ==K var(index, NEW, D, A, E)
    [label(swapDimsPromoteIndexNoMutation)]

  // SPEC-PROVENANCE:
  // - from_prompt: "Returns a new object with swapped dimensions." => result metadata changes, input metadata does not.
  // - from_docs: Dataset.swap_dims examples => promoted replacement variable becomes an IndexVariable in the result.
  claim <k> swapDimsPromoteV1(V, NEW) => . ... </k>
        <heap> V |-> var(base, OLD, D, A, E) => V |-> var(base, OLD, D, A, E) H </heap>
        <result> none => R </result>
        <fresh> N => N +Int 2 </fresh>
    requires V =/=Int N
     ensures R =/=Int V
      andBool H [ R ] ==K var(index, NEW, D, A, E)
    [label(swapDimsPromoteBaseNoMutation)]

  // SPEC-PROVENANCE:
  // - from_prompt: "not modify the original object" => non-promoted variables are also protected by the frame condition.
  // - from_code: to_base_variable() constructs a fresh Variable before dims assignment.
  claim <k> swapDimsBaseBranch(V, NEW) => . ... </k>
        <heap> V |-> var(K, OLD, D, A, E) => V |-> var(K, OLD, D, A, E) H </heap>
        <result> none => R </result>
        <fresh> N => N +Int 1 </fresh>
    requires V =/=Int N
     ensures R =/=Int V
      andBool H [ R ] ==K var(base, NEW, D, A, E)
    [label(swapDimsBaseBranchNoMutation)]

  // SPEC-PROVENANCE:
  // - bug_witness: pre-V1 code used toIndex(V) directly, so an existing IndexVariable is mutated in place.
  // - This is not a desired-behavior claim; it localizes F-001.
  claim <k> swapDimsPromoteOld(V, NEW) => . ... </k>
        <heap> V |-> var(index, OLD, D, A, E) => V |-> var(index, NEW, D, A, E) H </heap>
        <result> none => V </result>
    [label(swapDimsOldPromoteBugWitness)]

  // SPEC-PROVENANCE:
  // - from_code/public behavior: validation checks occur before the edited loop and are unchanged by V1.
  // - This claim is represented as a frame claim over the modeled body: no validation state is introduced or consumed here.
  claim <k> swapDimsPromoteV1(V, NEW) => . ... </k>
        <heap> H => H2 </heap>
        <result> none => R </result>
    requires validSwapDimsInput
     ensures validSwapDimsInput
    [label(swapDimsValidationFrame)]

  syntax Bool ::= "validSwapDimsInput" [function]
  rule validSwapDimsInput => true
endmodule
