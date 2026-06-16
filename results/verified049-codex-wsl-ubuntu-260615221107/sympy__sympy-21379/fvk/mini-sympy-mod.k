module MINI-SYMPY-MOD-SYNTAX
  imports BOOL-SYNTAX

  syntax Expr ::= "pPiecewiseQuotient"
                | "one"
                | "pi"
                | "p"
                | "q"
                | "g"

  syntax GcdOutcome ::= "gcdOk" "(" Expr ")"
                      | "gcdPolynomialError"

  syntax Result ::= "symbolicMod" "(" Expr "," Expr "," Expr ")"
                  | "zeroDivisionError"
                  | "polynomialError"

  syntax Eval ::= "modEval" "(" Expr "," Expr "," GcdOutcome ")"
                | "afterDoit" "(" Expr "," Expr "," GcdOutcome ")"
                | "afterPrep" "(" Expr "," Expr "," GcdOutcome ")"
                | "afterGcd" "(" Expr "," Expr "," Expr ")"
                | Result

  syntax Bool ::= "isZeroDivisor" "(" Expr ")" [function]
                | "hasEarlyResult" "(" Expr "," Expr ")" [function]

  syntax KResult ::= Result
endmodule

module MINI-SYMPY-MOD
  imports MINI-SYMPY-MOD-SYNTAX
  imports BOOL

  configuration <k> $PGM:Eval </k>

  // Models the existing zero-divisor guard before the optional gcd extraction.
  rule <k> modEval(P:Expr, Q:Expr, GO:GcdOutcome) => zeroDivisionError </k>
    requires isZeroDivisor(Q)

  // Models reaching the section after direct `doit` evaluation returns None.
  rule <k> modEval(P:Expr, Q:Expr, GO:GcdOutcome) => afterDoit(P, Q, GO) </k>
    requires notBool isZeroDivisor(Q) andBool notBool hasEarlyResult(P, Q)

  // Add/Mul/denesting preparation is abstracted because the proof target is the
  // gcd extraction edge. The property axis, escaped PolynomialError vs fallback,
  // remains explicit in GcdOutcome.
  rule <k> afterDoit(P:Expr, Q:Expr, GO:GcdOutcome) => afterPrep(P, Q, GO) </k>

  // V1 behavior: PolynomialError from optional gcd extraction falls back to G=1.
  rule <k> afterPrep(P:Expr, Q:Expr, gcdPolynomialError) => afterGcd(P, Q, one) </k>

  // Successful extraction preserves the successful gcd factor.
  rule <k> afterPrep(P:Expr, Q:Expr, gcdOk(G:Expr)) => afterGcd(P, Q, G) </k>

  // The remaining Mod construction/simplification is outside this audit and is
  // represented as a symbolic Mod result parameterized by P, Q, and G.
  rule <k> afterGcd(P:Expr, Q:Expr, G:Expr) => symbolicMod(P, Q, G) </k>
endmodule
