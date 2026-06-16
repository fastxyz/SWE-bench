module MINI-SPARSE-JOIN-SYNTAX
  imports INT-SYNTAX

  syntax Shape ::= "shape" "(" Int "," Int ")"
  syntax Shapes ::= ".Shapes"
                  | Shape ";" Shapes [right]
  syntax Result ::= Shape | "shapeError"
  syntax Cmd ::= "rowJoin" "(" Shape "," Shape ")"
               | "colJoin" "(" Shape "," Shape ")"
               | "hstackShapes" "(" Shapes ")"
               | "vstackShapes" "(" Shapes ")"
  syntax KResult ::= Result
endmodule

module MINI-SPARSE-JOIN
  imports MINI-SPARSE-JOIN-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Cmd </k>

  syntax Result ::= rowJoinResult(Result, Shape) [function]
  syntax Result ::= colJoinResult(Result, Shape) [function]
  syntax Result ::= hstackAcc(Result, Shapes) [function]
  syntax Result ::= vstackAcc(Result, Shapes) [function]

  // Sparse row_join shape semantics after V1.
  rule rowJoinResult(shape(R1, 0), shape(R2, C2)) => shape(R2, C2)
    requires R1 >=Int 0 andBool R2 >=Int 0 andBool C2 >=Int 0
  rule rowJoinResult(shape(R, C1), shape(R, C2)) => shape(R, C1 +Int C2)
    requires R >=Int 0 andBool C1 >Int 0 andBool C2 >=Int 0
  rule rowJoinResult(shape(R1, C1), shape(R2, C2)) => shapeError
    requires R1 >=Int 0 andBool R2 >=Int 0 andBool C1 >Int 0
      andBool C2 >=Int 0 andBool R1 =/=Int R2
  rule rowJoinResult(shapeError, S) => shapeError

  // Sparse col_join shape semantics after V1.
  rule colJoinResult(shape(0, C1), shape(R2, C2)) => shape(R2, C2)
    requires C1 >=Int 0 andBool R2 >=Int 0 andBool C2 >=Int 0
  rule colJoinResult(shape(R1, C), shape(R2, C)) => shape(R1 +Int R2, C)
    requires R1 >Int 0 andBool R2 >=Int 0 andBool C >=Int 0
  rule colJoinResult(shape(R1, C1), shape(R2, C2)) => shapeError
    requires R1 >Int 0 andBool R2 >=Int 0 andBool C1 >=Int 0
      andBool C2 >=Int 0 andBool C1 =/=Int C2
  rule colJoinResult(shapeError, S) => shapeError

  // hstack/vstack reduce left-to-right, matching MatrixShaping.
  rule hstackAcc(ACC, .Shapes) => ACC
  rule hstackAcc(ACC, S ; SS) => hstackAcc(rowJoinResult(ACC, S), SS)
  rule vstackAcc(ACC, .Shapes) => ACC
  rule vstackAcc(ACC, S ; SS) => vstackAcc(colJoinResult(ACC, S), SS)

  rule <k> rowJoin(S1, S2) => rowJoinResult(S1, S2) ... </k>
  rule <k> colJoin(S1, S2) => colJoinResult(S1, S2) ... </k>
  rule <k> hstackShapes(S ; SS) => hstackAcc(S, SS) ... </k>
  rule <k> vstackShapes(S ; SS) => vstackAcc(S, SS) ... </k>
endmodule
