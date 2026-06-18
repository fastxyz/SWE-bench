requires "mini-python.k"

module VERIFICATION
  imports MINI-PYTHON
  imports INT
  imports BOOL
  imports LIST

  syntax Int ::= "powMod" "(" Int "," Int "," Int ")" [function, smtlib(powMod)]
  syntax Bool ::= "isNthRoot" "(" Int "," Int "," Int "," Int ")" [function]
  syntax Bool ::= "exactlyZeroRootList" "(" List "," Int "," Int "," Int ")" [function]

  rule powMod(0, N:Int, P:Int) => 0
    requires N >Int 0 andBool P >Int 0
    [simplification]

  rule isNthRoot(0, A:Int, N:Int, P:Int) => true
    requires N >Int 0 andBool P >Int 0 andBool A modInt P ==Int 0
    [simplification]

  rule exactlyZeroRootList(ListItem(0), A:Int, N:Int, P:Int) => true
    requires N >Int 0 andBool P >Int 0 andBool A modInt P ==Int 0
    [simplification]

  // Mirrors is_nthpow_residue's public zero-residue fact in side conditions.
  rule nthResidue(A:Int, N:Int, P:Int) => true
    requires N >Int 0 andBool P >Int 0 andBool A >=Int 0 andBool A modInt P ==Int 0
    [simplification]
endmodule
