requires "domains.md"

module MINI-SEPARABILITY-SYNTAX
  imports INT
  imports BOOL

  syntax Matrix
  syntax Matrix ::= cstack(Matrix, Matrix) [function]
  syntax Int ::= rows(Matrix) [function]
  syntax Int ::= cols(Matrix) [function]
  syntax Bool ::= dep(Matrix, Int, Int) [function]
endmodule

module MINI-SEPARABILITY
  imports MINI-SEPARABILITY-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:K </k>

  // Abstract semantics for the matrix branch of _cstack.
  rule rows(cstack(L, R)) => rows(L) +Int rows(R)
  rule cols(cstack(L, R)) => cols(L) +Int cols(R)

  rule dep(cstack(L, R), I, J) => dep(L, I, J)
    requires 0 <=Int I andBool I <Int rows(L)
     andBool 0 <=Int J andBool J <Int cols(L)

  rule dep(cstack(L, R), I, J) => false
    requires 0 <=Int I andBool I <Int rows(L)
     andBool cols(L) <=Int J andBool J <Int cols(L) +Int cols(R)

  rule dep(cstack(L, R), I, J) => false
    requires rows(L) <=Int I andBool I <Int rows(L) +Int rows(R)
     andBool 0 <=Int J andBool J <Int cols(L)

  rule dep(cstack(L, R), I, J) => dep(R, I -Int rows(L), J -Int cols(L))
    requires rows(L) <=Int I andBool I <Int rows(L) +Int rows(R)
     andBool cols(L) <=Int J andBool J <Int cols(L) +Int cols(R)
endmodule
