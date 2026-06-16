module MINI-PYTHON-PRINTER-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Format ::= bareMpf | fullMpmathMpf
  syntax Rat ::= rat(Int, Int)

  // Abstract syntax for generated Python fragments.  This keeps the property
  // under verification visible: bare integer division and mpmath-wrapped
  // division are different constructors.
  syntax PyExpr ::= intLit(Int)
                  | mpfCall(Format, Int)
                  | div(PyExpr, PyExpr)
                  | neg(PyExpr)

  syntax PExp ::= printRational(Format, Rat)
  syntax KResult ::= PyExpr
endmodule

module MINI-PYTHON-PRINTER
  imports MINI-PYTHON-PRINTER-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:PExp </k>

  rule <k> printRational(F, rat(P, D)) => intLit(P) </k>
    requires D ==Int 1

  rule <k> printRational(F, rat(P, D)) => div(mpfCall(F, P), mpfCall(F, D)) </k>
    requires D >Int 1 andBool P >=Int 0

  rule <k> printRational(F, rat(P, D)) => neg(div(mpfCall(F, 0 -Int P), mpfCall(F, D))) </k>
    requires D >Int 1 andBool P <Int 0
endmodule
