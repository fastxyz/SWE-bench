module MINI-PYCODE-INDEXED
  imports INT
  imports STRING
  imports BOOL

  syntax PyExpr ::= Sym(String)
                  | IntLit(Int)
                  | IndexedBase(PyExpr)
                  | Indexed(PyExpr, PyExprs)
                  | Idx(PyExpr)

  syntax PyExprs ::= PyExpr
                   | PyExpr "," PyExprs

  syntax String ::= render(PyExpr) [function]
                  | renderBase(PyExpr) [function]
                  | renderIndices(PyExprs) [function]

  syntax Bool ::= supported(PyExpr) [function]
                | supportedIndices(PyExprs) [function]

  // Minimal string semantics for the PythonCodePrinter fragment under audit.
  // Constructed, not machine-checked in this environment.
  rule render(Sym(S)) => S
  rule render(IntLit(I)) => Int2String(I)
  rule render(IndexedBase(B)) => render(B)
  rule render(Idx(L)) => render(L)
  rule render(Indexed(B, IS))
    => renderBase(B) +String "[" +String renderIndices(IS) +String "]"
    requires supported(B) andBool supportedIndices(IS)

  rule renderBase(IndexedBase(B)) => render(B)
  rule renderBase(B) => render(B) [owise]

  rule renderIndices(E) => render(E)
  rule renderIndices(E "," REST)
    => render(E) +String ", " +String renderIndices(REST)

  rule supported(Sym(_S)) => true
  rule supported(IntLit(_I)) => true
  rule supported(IndexedBase(B)) => supported(B)
  rule supported(Idx(L)) => supported(L)
  rule supported(Indexed(B, IS)) => supported(B) andBool supportedIndices(IS)

  rule supportedIndices(E) => supported(E)
  rule supportedIndices(E "," REST) => supported(E) andBool supportedIndices(REST)
endmodule
