module MINI-SYMPY-ARRAY-SYNTAX
  imports INT-SYNTAX

  syntax Dims ::= ".Dims"
                | Int ":" Dims [right]

  syntax Data ::= "scalar" "(" Int ")"
                | "flat" "(" Int ")"

  syntax Array ::= "arr" "(" Dims "," Int ")"

  syntax Exp ::= Int
               | Array
               | "mkDenseImmutable" "(" Dims "," Data ")"
               | "mkDenseMutable" "(" Dims "," Data ")"
               | "mkSparseImmutable" "(" Dims "," Data ")"
               | "mkSparseMutable" "(" Dims "," Data ")"
               | "len" "(" Exp ")"

  syntax KResult ::= Int | Array
endmodule

module MINI-SYMPY-ARRAY
  imports MINI-SYMPY-ARRAY-SYNTAX
  imports INT

  configuration <k> $PGM:Exp </k>

  syntax Int ::= product(Dims) [function]
  rule product(.Dims) => 1
  rule product(D:Int : REST:Dims) => D *Int product(REST)

  rule <k> mkDenseImmutable(SHAPE:Dims, DATA:Data) => arr(SHAPE, product(SHAPE)) ... </k>
  rule <k> mkDenseMutable(SHAPE:Dims, DATA:Data) => arr(SHAPE, product(SHAPE)) ... </k>
  rule <k> mkSparseImmutable(SHAPE:Dims, DATA:Data) => arr(SHAPE, product(SHAPE)) ... </k>
  rule <k> mkSparseMutable(SHAPE:Dims, DATA:Data) => arr(SHAPE, product(SHAPE)) ... </k>

  rule <k> len(arr(SHAPE:Dims, SIZE:Int)) => SIZE ... </k>
endmodule
