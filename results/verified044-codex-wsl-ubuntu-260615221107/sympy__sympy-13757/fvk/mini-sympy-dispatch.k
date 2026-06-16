module MINI-SYMPY-DISPATCH-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Gen ::= "gx"
  syntax Atom ::= "x" | "sminus2" | "nonpoly"

  syntax Obj ::= Expr(Atom)
               | SymInt(Atom)
               | Poly(Atom, Gen)
               | MatrixLike(Atom)

  syntax Result ::= PolyProduct(Obj, Obj)
                  | ExprProduct(Obj, Obj)
                  | UnevaluatedMul(Obj, Obj)

  syntax KResult ::= Obj | Result | Int | Bool

  syntax Result ::= dispatchMul(Obj, Obj)
                  | polyRmul(Obj, Obj)
  syntax Int ::= priority(Obj) [function]
  syntax Bool ::= canPoly(Obj, Gen) [function]
                | isPolyObj(Obj) [function]
  syntax Obj ::= asPoly(Obj, Gen) [function]
endmodule

module MINI-SYMPY-DISPATCH
  imports MINI-SYMPY-DISPATCH-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:K </k>

  // Scale SymPy float priorities by 1000: Expr=10.0, Poly=10.001,
  // matrix-like dispatch owners model the higher concrete-matrix stratum.
  rule priority(Expr(_))       => 10000
  rule priority(SymInt(_))     => 10000
  rule priority(Poly(_, _))    => 10001
  rule priority(MatrixLike(_)) => 10010

  rule canPoly(Expr(x), gx)       => true
  rule canPoly(SymInt(sminus2), gx) => true
  rule canPoly(Expr(nonpoly), gx) => false

  rule asPoly(Expr(x), gx)         => Poly(x, gx)
  rule asPoly(SymInt(sminus2), gx) => Poly(sminus2, gx)

  // The modeled core of call_highest_priority('__rmul__') for multiplication.
  rule <k> dispatchMul(L:Obj, P:Obj) => polyRmul(P, L) ... </k>
    requires priority(P) >Int priority(L)
     andBool isPolyObj(P)

  rule <k> dispatchMul(L:Obj, R:Obj) => UnevaluatedMul(L, R) ... </k>
    requires notBool (priority(R) >Int priority(L) andBool isPolyObj(R))

  rule isPolyObj(Poly(_, _)) => true
  rule isPolyObj(Expr(_)) => false
  rule isPolyObj(SymInt(_)) => false
  rule isPolyObj(MatrixLike(_)) => false

  // The modeled core of Poly.__rmul__: convert if possible, otherwise fall
  // back to expression multiplication with the polynomial's expression form.
  rule <k> polyRmul(Poly(A, G), L:Obj) => PolyProduct(asPoly(L, G), Poly(A, G)) ... </k>
    requires canPoly(L, G)

  rule <k> polyRmul(Poly(A, G), L:Obj) => ExprProduct(L, Poly(A, G)) ... </k>
    requires notBool canPoly(L, G)
endmodule
