module MINI-PYTHON-DATEFORMAT-SYNTAX
  imports INT-SYNTAX

  syntax Exp ::= Int
               | Exp "%" Exp          [seqstrict, left]
               | "pad2" "(" Exp ")"   [strict]
               | "dateformatY" "(" Exp ")" [strict]

  syntax Digits2 ::= "digits2" "(" Int "," Int ")"
  syntax KResult ::= Int | Digits2
endmodule

module MINI-PYTHON-DATEFORMAT
  imports MINI-PYTHON-DATEFORMAT-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  rule <k> I1:Int % I2:Int => I1 modInt I2 ... </k>
    requires I2 =/=Int 0

  rule <k> pad2(N:Int) => digits2(N /Int 10, N modInt 10) ... </k>
    requires 0 <=Int N andBool N <=Int 99

  rule <k> dateformatY(Y:Int) => pad2(Y % 100) ... </k>
    requires 1 <=Int Y andBool Y <=Int 9999
endmodule
