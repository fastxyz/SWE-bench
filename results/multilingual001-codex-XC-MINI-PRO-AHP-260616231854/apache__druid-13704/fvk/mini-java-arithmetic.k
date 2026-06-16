module MINI-JAVA-ARITHMETIC-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Op ::= PLUS | MINUS | MULT | DIV | QUOTIENT | POW
  syntax CacheMode ::= Preserve | Ignore

  // Abstract Java double values. The model proves dispatch to Math.pow,
  // not the internals of the JDK floating-point implementation.
  syntax DVal ::= d(String) | null
                | plus(DVal, DVal)       [function]
                | minus(DVal, DVal)      [function]
                | mult(DVal, DVal)       [function]
                | divZeroSafe(DVal, DVal) [function]
                | quotient(DVal, DVal)   [function]
                | mathPow(DVal, DVal)    [function]

  syntax DVals ::= nil | cons(DVal, DVals)

  syntax Exp ::= lookup(String)
               | opCompute(Op, DVal, DVal)
               | compute(Op, DVals)
               | computeTail(Op, DVal, DVals)
               | cacheMode(Op)

  syntax KResult ::= Op | CacheMode | DVal | Bool
endmodule

module MINI-JAVA-ARITHMETIC
  imports MINI-JAVA-ARITHMETIC-SYNTAX
  imports BOOL
  imports K-EQUAL

  configuration <k> $PGM:Exp </k>

  rule <k> lookup("+") => PLUS ... </k>
  rule <k> lookup("-") => MINUS ... </k>
  rule <k> lookup("*") => MULT ... </k>
  rule <k> lookup("/") => DIV ... </k>
  rule <k> lookup("quotient") => QUOTIENT ... </k>
  rule <k> lookup("pow") => POW ... </k>

  rule <k> opCompute(PLUS, A:DVal, B:DVal) => plus(A, B) ... </k>
  rule <k> opCompute(MINUS, A:DVal, B:DVal) => minus(A, B) ... </k>
  rule <k> opCompute(MULT, A:DVal, B:DVal) => mult(A, B) ... </k>
  rule <k> opCompute(DIV, A:DVal, B:DVal) => divZeroSafe(A, B) ... </k>
  rule <k> opCompute(QUOTIENT, A:DVal, B:DVal) => quotient(A, B) ... </k>
  rule <k> opCompute(POW, A:DVal, B:DVal) => mathPow(A, B) ... </k>

  rule <k> compute(OP:Op, nil) => null ... </k>
  rule <k> compute(OP:Op, cons(null, XS:DVals)) => null ... </k>
  rule <k> compute(OP:Op, cons(A:DVal, XS:DVals)) => computeTail(OP, A, XS) ... </k>
    requires A =/=K null

  rule <k> computeTail(OP:Op, ACC:DVal, nil) => ACC ... </k>
  rule <k> computeTail(OP:Op, ACC:DVal, cons(null, XS:DVals)) => null ... </k>
  rule <k> computeTail(OP:Op, ACC:DVal, cons(B:DVal, XS:DVals))
        => computeTail(OP, opCompute(OP, ACC, B), XS) ... </k>
    requires B =/=K null

  rule <k> cacheMode(PLUS) => Ignore ... </k>
  rule <k> cacheMode(MULT) => Ignore ... </k>
  rule <k> cacheMode(MINUS) => Preserve ... </k>
  rule <k> cacheMode(DIV) => Preserve ... </k>
  rule <k> cacheMode(QUOTIENT) => Preserve ... </k>
  rule <k> cacheMode(POW) => Preserve ... </k>
endmodule
