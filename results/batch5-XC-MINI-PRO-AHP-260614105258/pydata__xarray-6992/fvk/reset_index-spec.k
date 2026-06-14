// Reachability claims for the post-loop core of Dataset.reset_index.
// Proves the class invariant ``coord_names ⊆ keys(variables)`` is *preserved*
// (hence DataVariables.__len__ >= 0), under the precondition that the input
// Dataset is well-formed (``self._coord_names ⊆ keys(self._variables)``).

requires "reset_index.k"

module RESET-INDEX-SPEC-SYNTAX
  imports RESET-INDEX-SYNTAX
endmodule

module VERIFICATION
  imports RESET-INDEX-SPEC-SYNTAX
  imports RESET-INDEX
  imports SET
  imports K-EQUAL

  // spec-only abstraction: A ⊆ B  ===  (A \ B) is empty
  syntax Bool ::= subset(Set, Set) [function, total]
  rule subset(A:Set, B:Set) => (A -Set B) ==K .Set

  // ---- set-algebra [simplification] lemmas the VC needs ----------------------
  // (L1) monotonicity of difference under a fixed subtrahend:
  //      if A ⊆ B then A\D ⊆ B\D
  rule subset(A:Set -Set D:Set, B:Set -Set D:Set) => true
    requires subset(A, B) [simplification]

  // (L2) a union is a superset of each operand: X ⊆ X|Y  and  Y ⊆ X|Y
  rule subset(A:Set, A:Set |Set _:Set) => true [simplification]
  rule subset(B:Set, _:Set |Set B:Set) => true [simplification]

  // (L3) union is monotone in its left operand against a shared right operand:
  //      if A ⊆ B then A|N ⊆ B|N
  rule subset(A:Set |Set N:Set, B:Set |Set N:Set) => true
    requires subset(A, B) [simplification]
endmodule

module RESET-INDEX-SPEC
  imports VERIFICATION

  // SPEC-PROVENANCE:
  // - from_prompt (PROBLEM.md): "we can end up with more `_coord_names` than
  //   `_variables` which breaks a number of stuff (e.g. the repr)" and
  //   "ValueError: __len__() should return >= 0"
  //     => POSTCONDITION: coord_names ⊆ keys(variables)  (so __len__ >= 0).
  // - from_code (dataset.py DataVariables.__len__): len(_variables) - len(_coord_names)
  //     => the quantity that must stay non-negative is |keys(variables)| - |coord_names|.
  // - from_code (dataset.py set_index, line 4102):
  //     coord_names = self._coord_names - set(drop_variables) | set(new_variables)
  //     => the sibling method already keeps the invariant this way (frame/consistency).
  // - precondition: the *input* Dataset is well-formed, i.e. subset(C, V).
  //
  // Program (lowercase = program vars; UPPERCASE = logical Set values):
  //   pv = keys(self._variables),  pc = self._coord_names,
  //   pd = set(drop_variables),    pn = set(new_variables)
  //     vk = (pv - pd) | pn        // keys(variables) after filter + update
  //     cn = (pc - pd) | pn        // coord_names (the FIXED line)
  //     return  cn <= vk           // the invariant: coord_names ⊆ keys(variables)
  claim
    <k>
      vk = ( pv - pd ) | pn ;
      cn = ( pc - pd ) | pn ;
      return cn <= vk ;
      => true
    </k>
    <store>
      pv |-> V:Set
      pc |-> C:Set
      pd |-> D:Set
      pn |-> N:Set
      ( .Map => ?_:Map )          // vk, cn allocated to some values
    </store>
    requires subset(C, V)          // input invariant: C ⊆ V
    [all-path]
endmodule
