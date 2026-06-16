// Constructed mini semantics for the diophantine syms-remapping entry path.
// This is not machine-checked in this environment.

module MINI-DIOPHANTINE-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax Eq ::= eqToken(String) [function]
  syntax Param ::= paramToken(String) [function]
  syntax Sym ::= symToken(String) [function]
  syntax Syms ::= List{Sym, ","} [klabel(syms)]
  syntax Tuple ::= List{Int, ","} [klabel(tuple)]

  syntax SolSet ::= canonicalSolve(Eq, Bool) [function]
                  | remapAll(SolSet, Syms, Syms) [function]

  syntax Syms ::= vars(Eq) [function]
  syntax Bool ::= isPermutationOf(Syms, Syms) [function]

  syntax Exp ::= diophantine(Eq, Param, Syms, Bool)
  syntax KResult ::= SolSet
endmodule

module MINI-DIOPHANTINE
  imports MINI-DIOPHANTINE-SYNTAX
  imports BOOL
  imports K-EQUAL

  configuration <k> $PGM:Exp </k>

  // The audited source branch:
  //   if syms != var:
  //       return {tuple(t[index_of_var[i]] for i in syms)
  //               for t in diophantine(eq, param, permute=permute)}
  //
  // The deeper algebraic solver is abstracted as canonicalSolve(EQ, PERMUTE).
  // The abstraction keeps the PERMUTE argument visible, so the V0 bug
  // canonicalSolve(EQ, false) and the V2 behavior canonicalSolve(EQ, true)
  // remain distinguishable.
  rule
    <k> diophantine(EQ:Eq, PARAM:Param, SYMS:Syms, PERMUTE:Bool)
        => remapAll(canonicalSolve(EQ, PERMUTE), SYMS, vars(EQ)) </k>
    requires isPermutationOf(SYMS, vars(EQ)) andBool SYMS =/=K vars(EQ)
endmodule
