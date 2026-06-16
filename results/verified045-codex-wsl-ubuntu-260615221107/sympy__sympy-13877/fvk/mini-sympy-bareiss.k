module MINI-SYMPY-BAREISS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Val ::= "zero" | "nan" | "exprZero" | "exprNonZero" | "atomNonZero"
  syntax Vals ::= ".Vals" | Val "," Vals [klabel(vals)]
  syntax Pivot ::= "noPivot" | "pivot" "(" Int "," Val ")"

  syntax Bool ::= "truthy" "(" Val ")" [function]
                | "isExpr" "(" Val ")" [function]
                | "hasNan" "(" Vals ")" [function]
  syntax Val ::= "expand" "(" Val ")" [function]
  syntax Exp ::= "findPivot" "(" Vals ")"
               | "findPivotAt" "(" Int "," Vals ")"
               | "findPivotExpanded" "(" Int "," Val "," Vals ")"
               | "detGuard" "(" Vals ")"

  syntax KResult ::= Bool | Val | Vals | Pivot
endmodule

module MINI-SYMPY-BAREISS
  imports MINI-SYMPY-BAREISS-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  rule truthy(zero) => false
  rule truthy(nan) => true
  rule truthy(exprZero) => true
  rule truthy(exprNonZero) => true
  rule truthy(atomNonZero) => true

  rule isExpr(exprZero) => true
  rule isExpr(exprNonZero) => true
  rule isExpr(zero) => false
  rule isExpr(nan) => false
  rule isExpr(atomNonZero) => false

  rule expand(exprZero) => zero
  rule expand(exprNonZero) => exprNonZero
  rule expand(zero) => zero
  rule expand(nan) => nan
  rule expand(atomNonZero) => atomNonZero

  rule hasNan(.Vals) => false
  rule hasNan(nan, VS:Vals) => true
  rule hasNan(V:Val, VS:Vals) => hasNan(VS) requires V =/=K nan

  rule detGuard(M:Vals) => nan requires hasNan(M) ==Bool true

  rule findPivot(VS:Vals) => findPivotAt(0, VS)
  rule findPivotAt(I:Int, .Vals) => noPivot
  rule findPivotAt(I:Int, V:Val, VS:Vals) => findPivotExpanded(I, expand(V), VS)
    requires truthy(V) ==Bool true andBool isExpr(V) ==Bool true
  rule findPivotAt(I:Int, V:Val, VS:Vals) => pivot(I, V)
    requires truthy(V) ==Bool true andBool isExpr(V) ==Bool false
  rule findPivotAt(I:Int, V:Val, VS:Vals) => findPivotAt(I +Int 1, VS)
    requires truthy(V) ==Bool false
  rule findPivotExpanded(I:Int, zero, VS:Vals) => findPivotAt(I +Int 1, VS)
  rule findPivotExpanded(I:Int, V:Val, VS:Vals) => pivot(I, V)
    requires truthy(V) ==Bool true
endmodule
