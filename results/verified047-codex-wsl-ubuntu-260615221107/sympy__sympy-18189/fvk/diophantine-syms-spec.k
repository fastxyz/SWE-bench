// Constructed K claims for the diophantine syms-remapping fix.
// These claims are constructed, not machine-checked in this environment.

requires "mini-diophantine.k"

module DIOPHANTINE-SYMS-SPEC
  imports MINI-DIOPHANTINE

  // SPEC-PROVENANCE:
  // - from_prompt: "incomplete results depending on syms order with permute=True"
  //   => permute=True must be preserved when syms order forces remapping.
  // - from_docstring: "syms ... determines the order of the elements" and
  //   "If permute is set to True then permutations ... will be returned"
  //   => syms controls tuple order; permute controls expansion of the set.
  // - from_code: canonical recursive solve returns tuples in vars(EQ) order.
  claim
    <k> diophantine(EQ:Eq, PARAM:Param, SYMS:Syms, true)
        => remapAll(canonicalSolve(EQ, true), SYMS, vars(EQ)) </k>
    requires isPermutationOf(SYMS, vars(EQ)) andBool SYMS =/=K vars(EQ)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docstring: "By default, only the base solution is returned"
  //   => permute=False remains the base-solution path.
  // - frame condition: V2 changes only argument propagation and tuple
  //   reindexing; it does not change the public function signature.
  claim
    <k> diophantine(EQ:Eq, PARAM:Param, SYMS:Syms, false)
        => remapAll(canonicalSolve(EQ, false), SYMS, vars(EQ)) </k>
    requires isPermutationOf(SYMS, vars(EQ)) andBool SYMS =/=K vars(EQ)
    [all-path]
endmodule
