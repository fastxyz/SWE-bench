requires "mini-xarray-reset-index.k"

module MINI-XARRAY-RESET-INDEX-SPEC
  imports MINI-XARRAY-RESET-INDEX
  imports BOOL
  imports SET

  syntax Bool ::= subset(Set, Set) [function]

  // Set-theory lemma for PO-2:
  // if N is a subset of V, then (C intersect V) union N is also a subset of V.
  rule subset((C:Set &Set V:Set) |Set N:Set, V:Set) => true
    requires subset(N, V) ==Bool true
    [simplification]

  // SPEC-PROVENANCE:
  // - from_prompt: "more `_coord_names` than `_variables` ... breaks ... repr"
  //   => rebuilt coordinate names must not contain names absent from variables.
  // - from_docs: "If True, remove the specified indexes and/or multi-index
  //   levels" => names removed from variables by drop=True must not remain as
  //   coordinates unless recreated as new index variables.
  // - from_public_tests: reset_index("x", drop=True) keeps level coordinates
  //   after dropping the multi-index array coordinate.
  // - from_code: new_variables are inserted into variables before coord_names
  //   is computed, so N is a subset of V in all reachable states.
  claim
    <k> rebuildCoordNames(C:Set, V:Set, N:Set) => .K ... </k>
    <coordNames> _ => CPrime:Set </coordNames>
    requires subset(N, V) ==Bool true
    ensures subset(CPrime, V) ==Bool true
    [all-path]

  // SPEC-PROVENANCE:
  // - exact postcondition for the source expression under audit.
  claim
    <k> rebuildCoordNames(C:Set, V:Set, N:Set) => .K ... </k>
    <coordNames> _ => (C &Set V) |Set N </coordNames>
    [all-path]
endmodule
