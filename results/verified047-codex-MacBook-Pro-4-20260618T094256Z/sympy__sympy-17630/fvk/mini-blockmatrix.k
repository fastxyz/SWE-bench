module MINI-BLOCKMATRIX-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax BM ::= bm(Id)
              | product(BM, BM)                 [function]

  syntax Other ::= block(BM)
                 | nonBlock(Id)

  syntax Block ::= matBlock(Int, Int, Id)
                 | zeroMatrix(Int, Int)

  syntax Entry ::= Block
                 | scalarZero

  syntax Fallback ::= fallback(BM, Other)

  syntax Exp ::= blockMul(BM, Other)
               | resultEntry(BM, BM, Int, Int)
               | normalize(Entry, Int, Int)
               | entry(BM, Int, Int)
               | entryRows(BM, Int, Int)
               | entryCols(BM, Int, Int)
               | isMatrixEntry(BM, Int, Int)

  syntax KResult ::= BM | Entry | Fallback | Bool | Int
endmodule

module MINI-BLOCKMATRIX
  imports MINI-BLOCKMATRIX-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  syntax Bool ::= compatible(BM, BM)             [function, smtlib(compatible)]
  syntax Int ::= rowCount(BM)                    [function, smtlib(rowCount)]
               | colCount(BM)                    [function, smtlib(colCount)]
               | rowSize(BM, Int)                [function, smtlib(rowSize)]
               | colSize(BM, Int)                [function, smtlib(colSize)]
  syntax Entry ::= rawEntry(BM, BM, Int, Int)    [function]

  rule <k> blockMul(A:BM, block(B:BM)) => product(A, B) ... </k>
    requires compatible(A, B)

  rule <k> blockMul(A:BM, block(B:BM)) => fallback(A, block(B)) ... </k>
    requires notBool compatible(A, B)

  rule <k> blockMul(A:BM, nonBlock(X:Id)) => fallback(A, nonBlock(X)) ... </k>

  rule <k> resultEntry(A:BM, B:BM, I:Int, J:Int)
        => normalize(rawEntry(A, B, I, J), rowSize(A, I), colSize(B, J))
        ... </k>
    requires compatible(A, B)

  rule <k> normalize(scalarZero, R:Int, C:Int) => zeroMatrix(R, C) ... </k>

  rule <k> normalize(B:Block, _R:Int, _C:Int) => B ... </k>

  rule <k> entry(product(A:BM, B:BM), I:Int, J:Int)
        => normalize(rawEntry(A, B, I, J), rowSize(A, I), colSize(B, J))
        ... </k>
    requires compatible(A, B)

  rule <k> entryRows(product(A:BM, B:BM), I:Int, _J:Int)
        => rowSize(A, I) ... </k>
    requires compatible(A, B)

  rule <k> entryCols(product(A:BM, B:BM), _I:Int, J:Int)
        => colSize(B, J) ... </k>
    requires compatible(A, B)

  rule <k> isMatrixEntry(product(A:BM, B:BM), _I:Int, _J:Int)
        => true ... </k>
    requires compatible(A, B)

  rule rowCount(product(A:BM, B:BM)) => rowCount(A)
    requires compatible(A, B)

  rule colCount(product(A:BM, B:BM)) => colCount(B)
    requires compatible(A, B)
endmodule
