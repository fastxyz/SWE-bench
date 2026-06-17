// Constructed FVK artifact; not machine-checked in this session.
// This is a minimal semantics for the observable branch behavior of
// PolyElement.as_expr and FracElement.as_expr. It intentionally abstracts away
// full Python and full SymPy expression internals while preserving the property
// under audit: which Symbols value reaches exprFromDict.

module MINI-PYTHON-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Poly
  syntax Frac ::= frac(Poly, Poly)

  syntax Symbols
  syntax PolyDict

  syntax Expr ::= exprFromDict(PolyDict, Symbols) [function]
                | exprQuotient(Expr, Expr)       [function]

  syntax PolyDict ::= asExprDict(Poly)  [function]
  syntax Symbols  ::= ringSymbols(Poly) [function]
  syntax Int      ::= ringNgens(Poly)   [function]
                    | symbolLen(Symbols) [function]

  syntax SymbolArgs ::= noSymbols
                      | supplied(Symbols)

  syntax Program ::= polyAsExpr(Poly, SymbolArgs)
                   | fracAsExpr(Frac, SymbolArgs)

  syntax Result ::= ok(Expr)
                  | valueError

  syntax KResult ::= Result
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Program </k>

  rule <k> polyAsExpr(P:Poly, noSymbols)
        => ok(exprFromDict(asExprDict(P), ringSymbols(P))) </k>

  rule <k> polyAsExpr(P:Poly, supplied(SYMS:Symbols))
        => ok(exprFromDict(asExprDict(P), SYMS)) </k>
    requires symbolLen(SYMS) ==Int ringNgens(P)

  rule <k> polyAsExpr(P:Poly, supplied(SYMS:Symbols))
        => valueError </k>
    requires symbolLen(SYMS) =/=Int ringNgens(P)

  rule <k> fracAsExpr(frac(N:Poly, D:Poly), noSymbols)
        => ok(exprQuotient(
             exprFromDict(asExprDict(N), ringSymbols(N)),
             exprFromDict(asExprDict(D), ringSymbols(D)))) </k>

  rule <k> fracAsExpr(frac(N:Poly, D:Poly), supplied(SYMS:Symbols))
        => ok(exprQuotient(
             exprFromDict(asExprDict(N), SYMS),
             exprFromDict(asExprDict(D), SYMS))) </k>
    requires symbolLen(SYMS) ==Int ringNgens(N)
     andBool ringNgens(N) ==Int ringNgens(D)

  rule <k> fracAsExpr(frac(N:Poly, D:Poly), supplied(SYMS:Symbols))
        => valueError </k>
    requires symbolLen(SYMS) =/=Int ringNgens(N)
endmodule
