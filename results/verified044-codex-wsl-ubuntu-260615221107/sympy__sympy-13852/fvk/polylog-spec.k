requires "mini-sympy-polylog.k"

module POLYLOG-SPEC
  imports MINI-SYMPY-POLYLOG

  // SPEC-PROVENANCE:
  // - from_prompt: "polylog(2, Rational(1,2))" should be
  //   "-log(2)**2/2 + pi**2/12" => automatic construction-path value.
  claim
    <k> polylog(Two, Half) =>
        Sub(Div(Pow(Pi, Two), IntExpr(12)),
            Div(Pow(log(IntExpr(2)), Two), IntExpr(2))) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "polylog(1, z) and -log(1-z) are exactly the same function"
  //   and the exp_polar factor is not meaningful => function expansion result.
  claim
    <k> expand_func(polylog(One, Sym(z))) =>
        Neg(log(Sub(One, Sym(z)))) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_proof_finding: after adding the construction-path Li_2(1/2) value,
  //   lerchphi's rational-a expansion must not call a private method on the
  //   evaluated Add expression => route through expand_func.
  claim
    <k> lerch_polylog_term(Two, Half) =>
        Sub(Div(Pow(Pi, Two), IntExpr(12)),
            Div(Pow(log(IntExpr(2)), Two), IntExpr(2))) </k>
    [all-path]
endmodule
