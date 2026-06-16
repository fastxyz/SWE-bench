module MINI-PYTHON-PRINTING-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax Expr ::= expr(Int, String)

  syntax LExp ::= printSubs(Expr, String, String)
                | printMulFactor(String, LExp) [strict(2)]

  syntax KResult ::= String
endmodule

module MINI-PYTHON-PRINTING
  imports MINI-PYTHON-PRINTING-SYNTAX
  imports INT
  imports BOOL
  imports STRING

  configuration <k> $PGM:LExp </k>

  syntax String ::= parenthesize(Expr, Int) [function]

  rule parenthesize(expr(PREC, BODY), LEVEL)
    => "\\left(" +String BODY +String "\\right)"
    requires PREC <Int LEVEL

  rule parenthesize(expr(PREC, BODY), LEVEL)
    => BODY
    requires PREC >=Int LEVEL

  rule <k> printSubs(E, OLD, NEW)
        => "\\left. " +String parenthesize(E, 50)
           +String " \\right|_{\\substack{ " +String OLD
           +String "=" +String NEW +String " }}" ... </k>

  rule <k> printMulFactor(COEFF, TERM:String)
        => COEFF +String " " +String TERM ... </k>
endmodule
