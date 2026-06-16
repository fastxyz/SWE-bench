module MINI-SYMPY-MOD-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Expr ::= "modExpr" "(" Int "," Int ")"
                | "unchanged"

  syntax Stmt ::= "reduceCoeff" "(" Int "," Int "," Int "," Bool "," Bool "," Bool ")"
                | "checkEquivalent" "(" Int "," Int "," Int ")"

  syntax KResult ::= Expr | Bool
endmodule

module MINI-SYMPY-MOD
  imports MINI-SYMPY-MOD-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Stmt </k>

  // Python's integer modulo convention, using floor division.
  syntax Int ::= pyMod(Int, Int) [function]
  rule pyMod(C, Q) => C -Int (Q *Int (C divInt Q))
    requires Q =/=Int 0

  syntax Bool ::= coeffGuard(Bool, Bool, Bool, Int) [function]
  rule coeffGuard(COEFFINTEGER, DIVISORPLAIN, TAILINTEGER, Q)
    => COEFFINTEGER andBool DIVISORPLAIN andBool TAILINTEGER andBool Q =/=Int 0

  // Model of the V1 branch in sympy/core/mod.py lines 177-183.
  // Arguments are: coefficient C, integer tail T, divisor Q, and the
  // three boolean guard facts checked by the production code.
  rule <k> reduceCoeff(C, T, Q, true, true, true)
        => modExpr(pyMod(C, Q) *Int T, Q)
       </k>
    requires Q =/=Int 0

  // Guard failure preserves the previous normalization path.
  rule <k> reduceCoeff(C, T, Q, COEFFINTEGER, DIVISORPLAIN, TAILINTEGER)
        => unchanged
       </k>
    requires notBool coeffGuard(COEFFINTEGER, DIVISORPLAIN, TAILINTEGER, Q)

  // A proof helper: the old and new dividends have the same Python remainder.
  rule <k> checkEquivalent(C, T, Q)
        => pyMod(C *Int T, Q) ==Int pyMod(pyMod(C, Q) *Int T, Q)
       </k>
    requires Q =/=Int 0
endmodule
