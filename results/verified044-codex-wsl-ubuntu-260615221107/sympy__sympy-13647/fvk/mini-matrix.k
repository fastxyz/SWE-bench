module MINI-MATRIX-SYNTAX
  imports INT
  imports BOOL

  syntax Matrix
  syntax Val

  syntax Int ::= rows(Matrix) [function]
               | cols(Matrix) [function]

  syntax Val ::= cell(Matrix, Int, Int) [function]
               | specEntry(Matrix, Int, Matrix, Int, Int) [function]

  syntax Matrix ::= evalColInsert(Matrix, Int, Matrix) [function]
                  | specColInsert(Matrix, Int, Matrix) [function]

  syntax KItem ::= entry(Matrix, Int, Matrix, Int, Int)
                 | shapeRows(Matrix, Int, Matrix)
                 | shapeCols(Matrix, Int, Matrix)
                 | result(Val)
                 | resultInt(Int)
endmodule

module MINI-MATRIX
  imports MINI-MATRIX-SYNTAX

  configuration <k> $PGM:K </k>

  rule rows(evalColInsert(A, P, B)) => rows(A)
  rule cols(evalColInsert(A, P, B)) => cols(A) +Int cols(B)

  rule rows(specColInsert(A, P, B)) => rows(A)
  rule cols(specColInsert(A, P, B)) => cols(A) +Int cols(B)

  rule specEntry(A, P, B, I, J) => cell(A, I, J)
    requires J <Int P

  rule specEntry(A, P, B, I, J) => cell(B, I, J -Int P)
    requires P <=Int J andBool J <Int P +Int cols(B)

  rule specEntry(A, P, B, I, J) => cell(A, I, J -Int cols(B))
    requires P +Int cols(B) <=Int J

  rule <k> shapeRows(A, P, B) => resultInt(rows(A)) ... </k>

  rule <k> shapeCols(A, P, B) => resultInt(cols(A) +Int cols(B)) ... </k>

  rule <k> entry(A, P, B, I, J) => result(cell(A, I, J)) ... </k>
    requires J <Int P

  rule <k> entry(A, P, B, I, J) => result(cell(B, I, J -Int P)) ... </k>
    requires P <=Int J andBool J <Int P +Int cols(B)

  rule <k> entry(A, P, B, I, J) => result(cell(A, I, J -Int cols(B))) ... </k>
    requires P +Int cols(B) <=Int J
endmodule
