module MINI-PYTHON-NUMPY-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax Stmt ::= Id "=" Exp

  syntax Exp ::= Int
               | Id
               | Ints
               | Exp "+" Exp      [seqstrict, left]
               | Exp "*" Exp      [seqstrict, left]
               | "arange" "(" Exp ")" [strict]

  syntax Ints ::= ".Ints"                [klabel(.Ints)]
                | Int "," Ints           [klabel(ints)]

  syntax KResult ::= Int | Bool | Ints
endmodule

module MINI-PYTHON-NUMPY
  imports MINI-PYTHON-NUMPY-SYNTAX
  imports INT
  imports BOOL
  imports MAP

  configuration
    <k> $PGM:Stmt </k>
    <store> .Map </store>

  syntax Ints ::= range(Int, Int) [function]
                | scale(Ints, Int) [function]

  rule range(I:Int, STOP:Int) => .Ints
    requires I >=Int STOP
  rule range(I:Int, STOP:Int) => I , range(I +Int 1, STOP)
    requires I <Int STOP

  rule scale(.Ints, M:Int) => .Ints
  rule scale((I:Int , REST:Ints), M:Int) => (I *Int M) , scale(REST, M)

  rule <k> X:Id => V ... </k>
       <store> ... X |-> V ... </store>

  rule <k> I1:Int + I2:Int => I1 +Int I2 ... </k>
  rule <k> I1:Int * I2:Int => I1 *Int I2 ... </k>
  rule <k> IS:Ints * I:Int => scale(IS, I) ... </k>
  rule <k> arange(I:Int) => range(0, I) ... </k>

  rule <k> X:Id = V:KResult => .K ... </k>
       <store> STORE => STORE [ X <- V ] </store>
endmodule
