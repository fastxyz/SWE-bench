module MINI-HTTP-DATE-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Exp ::= normalize2(Int, Int)
               | century(Int)
               | candidate(Int, Int)
  syntax KResult ::= Int
endmodule

module MINI-HTTP-DATE
  imports MINI-HTTP-DATE-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  rule <k> century(CY:Int) => CY -Int (CY modInt 100) ... </k>
    requires CY >=Int 100

  rule <k> candidate(YY:Int, CY:Int) => (CY -Int (CY modInt 100)) +Int YY ... </k>
    requires CY >=Int 100 andBool 0 <=Int YY andBool YY <Int 100

  rule <k> normalize2(YY:Int, CY:Int)
        => (CY -Int (CY modInt 100)) +Int YY
        ... </k>
    requires CY >=Int 100
     andBool 0 <=Int YY andBool YY <Int 100
     andBool ((CY -Int (CY modInt 100)) +Int YY) <=Int CY +Int 50

  rule <k> normalize2(YY:Int, CY:Int)
        => ((CY -Int (CY modInt 100)) +Int YY) -Int 100
        ... </k>
    requires CY >=Int 100
     andBool 0 <=Int YY andBool YY <Int 100
     andBool ((CY -Int (CY modInt 100)) +Int YY) >Int CY +Int 50
endmodule
