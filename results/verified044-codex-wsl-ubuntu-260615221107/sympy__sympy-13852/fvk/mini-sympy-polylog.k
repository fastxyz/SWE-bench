module MINI-SYMPY-POLYLOG-SYNTAX
  imports INT-SYNTAX

  syntax Expr ::= "Zero" | "One" | "NegOne" | "Two" | "Half" | "Pi"
                | "Sym" "(" Id ")"
                | "IntExpr" "(" Int ")"
                | "Add" "(" Expr "," Expr ")"
                | "Sub" "(" Expr "," Expr ")"
                | "Mul" "(" Expr "," Expr ")"
                | "Div" "(" Expr "," Expr ")"
                | "Pow" "(" Expr "," Expr ")"
                | "Neg" "(" Expr ")"
                | "log" "(" Expr ")"
                | "zeta" "(" Expr ")"
                | "dirichlet_eta" "(" Expr ")"
                | "polylog" "(" Expr "," Expr ")"
                | "expand_func" "(" Expr ")"
                | "lerch_polylog_term" "(" Expr "," Expr ")"
                | "AttrError"

  syntax Id ::= r"[A-Za-z][A-Za-z0-9_]*" [token]
  syntax KResult ::= Expr
endmodule

module MINI-SYMPY-POLYLOG
  imports MINI-SYMPY-POLYLOG-SYNTAX
  imports INT
  imports ID

  configuration <k> $PGM:Expr </k>

  // SymPy Function.eval behavior for polylog's automatic special values.
  rule <k> polylog(S, One) => zeta(S) ... </k>
  rule <k> polylog(S, NegOne) => Neg(dirichlet_eta(S)) ... </k>
  rule <k> polylog(S, Zero) => Zero ... </k>
  rule <k> polylog(Two, Half) =>
             Sub(Div(Pow(Pi, Two), IntExpr(12)),
                 Div(Pow(log(IntExpr(2)), Two), IntExpr(2))) ... </k>

  // Function expansion behavior relevant to the issue.
  rule <k> expand_func(polylog(One, Z)) => Neg(log(Sub(One, Z))) ... </k>
  rule <k> expand_func(polylog(Zero, Z)) => Div(Z, Sub(One, Z)) ... </k>

  // Public expansion helper is total on already-evaluated expressions in this
  // abstraction: if no function rule applies, the expression is returned.
  rule <k> expand_func(E) => E ... </k> [owise]

  // Model the lerchphi rational-a contributor: it must route through the public
  // expansion helper so evaluated polylog values remain valid expressions.
  rule <k> lerch_polylog_term(S, Z) => expand_func(polylog(S, Z)) ... </k>
endmodule
