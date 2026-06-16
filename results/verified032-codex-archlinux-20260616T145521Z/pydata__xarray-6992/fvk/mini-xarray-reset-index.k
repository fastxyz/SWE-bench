requires "domains.md"

module MINI-XARRAY-RESET-INDEX-SYNTAX
  imports SET-SYNTAX

  syntax Cmd ::= "rebuildCoordNames" "(" Set "," Set "," Set ")"
endmodule

module MINI-XARRAY-RESET-INDEX
  imports MINI-XARRAY-RESET-INDEX-SYNTAX
  imports SET

  configuration
    <k> $PGM:Cmd </k>
    <coordNames> .Set </coordNames>

  // Abstract model of the audited source expression:
  //     self._coord_names & variables.keys() | set(new_variables)
  // C is the old coordinate-name set, V is the rebuilt variable-key set, and
  // N is the set of replacement index variables created by reset_index.
  rule
    <k> rebuildCoordNames(C:Set, V:Set, N:Set) => .K </k>
    <coordNames> _ => (C &Set V) |Set N </coordNames>
endmodule
