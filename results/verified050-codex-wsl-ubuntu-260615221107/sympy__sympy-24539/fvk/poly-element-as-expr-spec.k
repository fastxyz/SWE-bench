// Constructed FVK artifact; not machine-checked in this session.

requires "mini-python.k"

module POLY-ELEMENT-AS-EXPR-SPEC
  imports MINI-PYTHON

  // SPEC-PROVENANCE:
  // - E-5: public tests require no-argument conversion to use ring symbols.
  // - code: V1 assigns self.ring.symbols only when the varargs tuple is empty.
  claim [POLY-AS-EXPR-DEFAULT]:
    <k> polyAsExpr(P:Poly, noSymbols)
     => ok(exprFromDict(asExprDict(P), ringSymbols(P))) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-1/E-2: issue says callers must be able to set the symbols to use.
  // - E-3: using ringSymbols(P) for same-arity supplied symbols is the bug.
  // - E-7: expr_from_dict consumes the provided generators positionally.
  claim [POLY-AS-EXPR-SUPPLIED]:
    <k> polyAsExpr(P:Poly, supplied(SYMS:Symbols))
     => ok(exprFromDict(asExprDict(P), SYMS)) </k>
    requires symbolLen(SYMS) ==Int ringNgens(P)
    [all-path]

  // SPEC-PROVENANCE:
  // - E-4: wrong arity remains an error.
  // - code: V1 keeps the existing ValueError branch.
  claim [POLY-AS-EXPR-BAD-ARITY]:
    <k> polyAsExpr(P:Poly, supplied(SYMS:Symbols))
     => valueError </k>
    requires symbolLen(SYMS) =/=Int ringNgens(P)
    [all-path]

  // SPEC-PROVENANCE:
  // - E-8: FracElement.as_expr forwards symbols to numerator and denominator.
  // - compatibility: corrected PolyElement behavior should propagate.
  claim [FRAC-AS-EXPR-SUPPLIED]:
    <k> fracAsExpr(frac(N:Poly, D:Poly), supplied(SYMS:Symbols))
     => ok(exprQuotient(
          exprFromDict(asExprDict(N), SYMS),
          exprFromDict(asExprDict(D), SYMS))) </k>
    requires symbolLen(SYMS) ==Int ringNgens(N)
     andBool ringNgens(N) ==Int ringNgens(D)
    [all-path]
endmodule
