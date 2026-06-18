module MINI-LATEX-PRINTER-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Expr ::= "addExpr"
                | "mulExpr"
                | "atomExpr"
                | "derivativeExpr"

  syntax Assigns ::= "assignOne"
                   | "assignTwo"

  syntax Tex ::= "rawAdd"
               | "rawMul"
               | "rawAtom"
               | "rawDerivative"
               | "paren" "(" Tex ")"
               | "subsTex" "(" Tex "," Assigns ")"
               | "mulTex" "(" Tex "," Tex ")"
               | "numTex" "(" Int ")"

  syntax KResult ::= Tex
endmodule

module MINI-LATEX-PRINTER
  imports MINI-LATEX-PRINTER-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:K </k>

  syntax Int ::= prec(Expr) [function]
  rule prec(addExpr)        => 40
  rule prec(mulExpr)        => 50
  rule prec(atomExpr)       => 1000
  rule prec(derivativeExpr) => 50

  syntax Tex ::= render(Expr) [function]
  rule render(addExpr)        => rawAdd
  rule render(mulExpr)        => rawMul
  rule render(atomExpr)       => rawAtom
  rule render(derivativeExpr) => rawDerivative

  syntax Tex ::= parenthesize(Expr, Int, Bool) [function]
  rule parenthesize(E:Expr, LEVEL:Int, true)
    => paren(render(E))
    requires prec(E) <Int LEVEL
  rule parenthesize(E:Expr, LEVEL:Int, true)
    => render(E)
    requires notBool (prec(E) <Int LEVEL)
  rule parenthesize(E:Expr, LEVEL:Int, false)
    => paren(render(E))
    requires prec(E) <=Int LEVEL
  rule parenthesize(E:Expr, LEVEL:Int, false)
    => render(E)
    requires notBool (prec(E) <=Int LEVEL)

  syntax Tex ::= printSubs(Expr, Assigns) [function]
  rule printSubs(E:Expr, A:Assigns)
    => subsTex(parenthesize(E, 50, true), A)

  syntax Tex ::= printMulWithCoeff(Int, Expr, Assigns) [function]
  rule printMulWithCoeff(N:Int, E:Expr, A:Assigns)
    => mulTex(numTex(N), printSubs(E, A))

  // Diagnostic model of the legacy direct-rendering behavior reported by the
  // issue. It is not the candidate implementation contract.
  syntax Tex ::= printSubsLegacy(Expr, Assigns) [function]
  rule printSubsLegacy(E:Expr, A:Assigns)
    => subsTex(render(E), A)

  syntax Tex ::= printMulWithCoeffLegacy(Int, Expr, Assigns) [function]
  rule printMulWithCoeffLegacy(N:Int, E:Expr, A:Assigns)
    => mulTex(numTex(N), printSubsLegacy(E, A))
endmodule
