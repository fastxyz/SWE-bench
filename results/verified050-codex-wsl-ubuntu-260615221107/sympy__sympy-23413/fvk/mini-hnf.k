module MINI-HNF-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Matrix
  syntax Matrix ::= issueB() [function]
                  | issueH() [function]
                  | rankDefTop() [function]
                  | hnf(Matrix) [function]

  syntax Int ::= rows(Matrix) [function]
               | cols(Matrix) [function]
               | rank(Matrix) [function]

  syntax Bool ::= isZZMatrix(Matrix) [function]
                | isColumnHNF(Matrix) [function]
                | sameColumnModule(Matrix, Matrix) [function]

  syntax Exp ::= "hermite" "(" Matrix ")"
  syntax KResult ::= Matrix
endmodule

module MINI-HNF
  imports MINI-HNF-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // This mini semantics abstracts the Python implementation to the mathematical
  // HNF transformer while preserving the observable axes under audit: shape,
  // rank, column-module equality, and concrete issue output.
  rule <k> hermite(A:Matrix) => hnf(A) </k>
endmodule
