requires "domains.md"

module MINI-SYMPY-SURD-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  syntax Expr ::= "ZERO" | "ONE" | "THREE" | "ISSUE-BASE-4I"
                | "ISSUE-DEN-4I" | "CBRT-DEN" | "SQRT2-PLUS-I"
                | "SQRT2-MINUS-I" | "DOC-SURD-SUM" | "UNSUPPORTED"
  syntax Match ::= "NO-MATCH" | "MATCH" "(" Expr "," Expr "," Expr ")"
  syntax Split ::= "SPLIT" "(" Int "," Expr "," Expr ")"
  syntax Pair ::= "PAIR" "(" Expr "," Expr ")"
  syntax GcdSplit ::= "GCDSPLIT" "(" Int "," List "," List ")"

  syntax KItem ::= sqrtMatch(Expr)
                 | splitSurds(Expr)
                 | splitGcd(List)
                 | radRationalize(Expr, Expr)

  syntax Bool ::= isAdd(Expr) [function]
                | allSquaresRational(Expr) [function]
                | allSquaresPositive(Expr) [function]
                | hasHalfPowSurd(Expr) [function]

  syntax Int ::= maxSqrtDepth(Expr) [function]
end module

module MINI-SYMPY-SURD
  imports MINI-SYMPY-SURD-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration <k> $PGM:K </k>

  rule isAdd(ISSUE-BASE-4I) => true
  rule isAdd(ISSUE-DEN-4I) => true
  rule isAdd(CBRT-DEN) => true
  rule isAdd(SQRT2-PLUS-I) => true
  rule isAdd(DOC-SURD-SUM) => true
  rule isAdd(UNSUPPORTED) => true

  rule allSquaresRational(ISSUE-BASE-4I) => true
  rule allSquaresPositive(ISSUE-BASE-4I) => false

  rule hasHalfPowSurd(ISSUE-BASE-4I) => false
  rule hasHalfPowSurd(ISSUE-DEN-4I) => false
  rule hasHalfPowSurd(CBRT-DEN) => false
  rule hasHalfPowSurd(SQRT2-PLUS-I) => true
  rule hasHalfPowSurd(DOC-SURD-SUM) => true

  rule maxSqrtDepth(ISSUE-BASE-4I) => 0

  rule <k> sqrtMatch(E:Expr) => NO-MATCH ... </k>
    requires isAdd(E)
     andBool allSquaresRational(E)
     andBool notBool allSquaresPositive(E)
     andBool maxSqrtDepth(E) ==Int 0

  rule <k> splitSurds(E:Expr) => SPLIT(1, ZERO, E) ... </k>
    requires isAdd(E) andBool notBool hasHalfPowSurd(E)

  rule <k> splitGcd(.List) => GCDSPLIT(1, .List, .List) ... </k>

  rule <k> radRationalize(N:Expr, D:Expr) => PAIR(N, D) ... </k>
    requires isAdd(D) andBool notBool hasHalfPowSurd(D)

  rule <k> radRationalize(ONE, SQRT2-PLUS-I) => PAIR(SQRT2-MINUS-I, THREE) ... </k>
    requires hasHalfPowSurd(SQRT2-PLUS-I)
endmodule
