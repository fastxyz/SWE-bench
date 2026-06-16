module MINI-SYMPY-FU-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax ExpClass ::= nonInteger
                    | symbolicInteger
                    | concrete(Int)

  syntax PowMode ::= powFalse | powTrue

  syntax Decision ::= unchanged
                    | rewrite2
                    | rewriteHalf(Int)

  syntax KItem ::= tr56(ExpClass, Int, PowMode)
endmodule

module MINI-SYMPY-FU
  imports MINI-SYMPY-FU-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:K </k>

  // Spec abstraction for perfect_power(exp) with the V2 p[0] == 2 check.
  syntax Bool ::= isPowerOfTwo(Int) [function]
  rule isPowerOfTwo(2) => true
  rule isPowerOfTwo(4) => true
  rule isPowerOfTwo(6) => false
  rule isPowerOfTwo(8) => true
  rule isPowerOfTwo(9) => false
  rule isPowerOfTwo(36) => false

  // Non-integer exponents return before any ordered comparison.
  rule <k> tr56(nonInteger, MAX:Int, MODE:PowMode) => unchanged ... </k>

  // In pow=True mode, non-concrete integer exponents return before perfect_power.
  rule <k> tr56(symbolicInteger, MAX:Int, powTrue) => unchanged ... </k>

  // Unknown symbolic parity is not enough to rewrite in this abstraction.
  rule <k> tr56(symbolicInteger, MAX:Int, powFalse) => unchanged ... </k>

  rule <k> tr56(concrete(N:Int), MAX:Int, MODE:PowMode) => unchanged ... </k>
    requires N <Int 0

  rule <k> tr56(concrete(N:Int), MAX:Int, MODE:PowMode) => unchanged ... </k>
    requires N >=Int 0 andBool N >Int MAX

  rule <k> tr56(concrete(2), MAX:Int, MODE:PowMode) => rewrite2 ... </k>
    requires 2 <=Int MAX

  rule <k> tr56(concrete(4), MAX:Int, MODE:PowMode) => rewriteHalf(2) ... </k>
    requires 4 <=Int MAX

  rule <k> tr56(concrete(N:Int), MAX:Int, powFalse) => rewriteHalf(N /Int 2) ... </k>
    requires N >=Int 0
     andBool N <=Int MAX
     andBool N =/=Int 2
     andBool N =/=Int 4
     andBool N modInt 2 ==Int 0

  rule <k> tr56(concrete(N:Int), MAX:Int, powFalse) => unchanged ... </k>
    requires N >=Int 0
     andBool N <=Int MAX
     andBool N =/=Int 2
     andBool N =/=Int 4
     andBool N modInt 2 =/=Int 0

  rule <k> tr56(concrete(N:Int), MAX:Int, powTrue) => rewriteHalf(N /Int 2) ... </k>
    requires N >=Int 0
     andBool N <=Int MAX
     andBool N =/=Int 2
     andBool N =/=Int 4
     andBool isPowerOfTwo(N) ==Bool true

  rule <k> tr56(concrete(N:Int), MAX:Int, powTrue) => unchanged ... </k>
    requires N >=Int 0
     andBool N <=Int MAX
     andBool N =/=Int 2
     andBool N =/=Int 4
     andBool isPowerOfTwo(N) ==Bool false
endmodule
