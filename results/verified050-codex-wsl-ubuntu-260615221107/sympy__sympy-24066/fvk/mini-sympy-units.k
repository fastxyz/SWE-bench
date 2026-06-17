// Constructed, not machine-checked.
// Minimal K model for the UnitSystem._collect_factor_and_dimension branches
// relevant to sympy__sympy-24066. This is not full Python or full SymPy.

module MINI-SYMPY-UNITS-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Expr ::= "num100"
                | "rcExpr"
                | "lenExpr"
                | "unsupportedExpr"
                | "exp" "(" Expr ")"
                | "add" "(" Expr "," Expr ")"

  syntax Factor ::= "N100" | "FRC" | "FLEN" | "FUNSUPPORTED" | "E"
                  | "addF" "(" Factor "," Factor ")"
                  | "expF" "(" Factor ")"

  syntax Dim ::= "D1" | "DRC" | "DLEN" | "DUNSUPPORTED"

  syntax Result ::= "res" "(" Factor "," Dim ")"
                  | "err" "(" String ")"

  syntax KResult ::= Result | Factor | Dim | Bool
endmodule

module MINI-SYMPY-UNITS
  imports MINI-SYMPY-UNITS-SYNTAX
  imports BOOL

  configuration <k> $PGM:Expr </k>

  syntax Bool ::= isDimless(Dim) [function]
  rule isDimless(D1) => true
  rule isDimless(DRC) => true
  rule isDimless(DLEN) => false
  rule isDimless(DUNSUPPORTED) => false

  syntax Bool ::= equivDim(Dim, Dim) [function]
  rule equivDim(D1, D1) => true
  rule equivDim(DRC, D1) => true
  rule equivDim(D1, DRC) => true
  rule equivDim(DRC, DRC) => true
  rule equivDim(DLEN, DLEN) => true
  rule equivDim(DUNSUPPORTED, DUNSUPPORTED) => true
  rule equivDim(D1, DLEN) => false
  rule equivDim(DLEN, D1) => false
  rule equivDim(D1, DUNSUPPORTED) => false
  rule equivDim(DUNSUPPORTED, D1) => false
  rule equivDim(DLEN, DUNSUPPORTED) => false
  rule equivDim(DUNSUPPORTED, DLEN) => false
  rule equivDim(DRC, DLEN) => false
  rule equivDim(DLEN, DRC) => false
  rule equivDim(DRC, DUNSUPPORTED) => false
  rule equivDim(DUNSUPPORTED, DRC) => false

  syntax Dim ::= canonFuncDim(Dim) [function]
  rule canonFuncDim(D1) => D1
  rule canonFuncDim(DRC) => D1
  rule canonFuncDim(DLEN) => DLEN
  rule canonFuncDim(DUNSUPPORTED) => DUNSUPPORTED

  syntax Result ::= collect(Expr) [function]
  rule collect(num100) => res(N100, D1)
  rule collect(rcExpr) => res(FRC, DRC)
  rule collect(lenExpr) => res(FLEN, DLEN)
  rule collect(unsupportedExpr) => res(FUNSUPPORTED, DUNSUPPORTED)

  rule collect(exp(E:Expr)) => res(expF(F), canonFuncDim(D))
    requires collect(E) ==K res(F, D)

  rule collect(add(E1:Expr, E2:Expr)) => res(addF(F1, F2), D1)
    requires collect(E1) ==K res(F1, D1)
     andBool collect(E2) ==K res(F2, D1)

  rule collect(add(E1:Expr, E2:Expr)) => res(addF(F1, F2), D)
    requires collect(E1) ==K res(F1, D)
     andBool collect(E2) ==K res(F2, D2)
     andBool D =/=K D1
     andBool equivDim(D, D2)

  rule collect(add(E1:Expr, E2:Expr)) => err("incompatible-dimensions")
    requires collect(E1) ==K res(F1, D)
     andBool collect(E2) ==K res(F2, D2)
     andBool notBool equivDim(D, D2)
endmodule
