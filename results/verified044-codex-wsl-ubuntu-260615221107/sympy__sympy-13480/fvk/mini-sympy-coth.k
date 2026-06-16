module MINI-SYMPY-COTH-SYNTAX
  imports INT-SYNTAX

  // Focused expression vocabulary for the coth.eval additive-period branch.
  syntax Expr ::= "NoExpr"
                | "ComplexInfinity"
                | "Arg" "(" Int ")"
                | "Part" "(" Int ")"
                | "Coth" "(" Expr ")"
                | "Tanh" "(" Expr ")"
                | "CothValue" "(" Expr ")" [function]

  syntax Stmt ::= "cothEvalAddBranch" "(" Expr "," Expr "," Expr ")"
                | "bindCothm" "(" Expr "," Expr ")"
                | "chooseCothBranch" "(" Expr ")"
                | "return" Expr

  syntax KResult ::= Expr
endmodule

module MINI-SYMPY-COTH
  imports MINI-SYMPY-COTH-SYNTAX
  imports K-EQUAL

  // This is a mini-semantics for the already-reached branch:
  //     x, m = _peeloff_ipi(arg)
  //     if m:
  //         cothm = coth(m)
  //         if cothm is S.ComplexInfinity: return coth(x)
  //         else: return tanh(x)
  //
  // The earlier SymPy predicates are modeled as preconditions in the spec.
  configuration
    <k> $PGM:Stmt </k>
    <cothm> NoExpr </cothm>
    <result> NoExpr </result>

  rule <k> cothEvalAddBranch(_A, X, M) => bindCothm(M, X) ... </k>

  rule <k> bindCothm(M, X) => chooseCothBranch(X) ... </k>
       <cothm> _ => CothValue(M) </cothm>

  rule <k> chooseCothBranch(X) => return Coth(X) ... </k>
       <cothm> ComplexInfinity </cothm>

  rule <k> chooseCothBranch(X) => return Tanh(X) ... </k>
       <cothm> V:Expr </cothm>
    requires V =/=K ComplexInfinity

  rule <k> return V => .K </k>
       <result> _ => V </result>
endmodule
