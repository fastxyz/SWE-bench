requires "mini-sympy-dispatch.k"

module POLY-DISPATCH-SPEC
  imports MINI-SYMPY-DISPATCH
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: "Poly(x)*x -> Poly(x**2, x, domain='ZZ')" and
  //   "x*Poly(x) -> x*Poly(x, x, domain='ZZ')" => x on the left must
  //   dispatch to Poly.__rmul__ and produce a polynomial product.
  // - from_code: call_highest_priority delegates only on strict priority.
  claim
    <k> dispatchMul(Expr(x), Poly(x, gx))
      => PolyProduct(Poly(x, gx), Poly(x, gx)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "S(-2)*Poly(x) -> -2*Poly(x, x, domain='ZZ')" is the bug;
  //   "Poly(x)*S(-2) -> Poly(-2*x, x, domain='ZZ')" is the intended mirror.
  // - from_code: Poly.__rmul__ converts compatible non-Poly operands before
  //   calling polynomial multiplication.
  claim
    <k> dispatchMul(SymInt(sminus2), Poly(x, gx))
      => PolyProduct(Poly(sminus2, gx), Poly(x, gx)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: Poly.__rmul__ catches PolynomialError and returns
  //   g*f.as_expr(); this is a preservation obligation for incompatible
  //   expression operands, not a new polynomial-conversion requirement.
  claim
    <k> dispatchMul(Expr(nonpoly), Poly(x, gx))
      => ExprProduct(Expr(nonpoly), Poly(x, gx)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: Expr._op_priority is 10.0 and V1 gives Poly 10.001.
  // - from_prompt: the right-hand Poly must be selected over ordinary Expr.
  claim
    <k> priority(Poly(x, gx)) >Int priority(Expr(x)) => true </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_compatibility_audit: the Poly priority is intentionally below the
  //   modeled matrix-like higher dispatch stratum.
  claim
    <k> priority(Poly(x, gx)) <=Int priority(MatrixLike(x)) => true </k>
    [all-path]
endmodule
