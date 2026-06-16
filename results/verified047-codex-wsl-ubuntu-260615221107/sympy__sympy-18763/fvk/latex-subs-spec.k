requires "mini-python-printing.k"

module LATEX-SUBS-SPEC
  imports MINI-PYTHON-PRINTING

  // SPEC-PROVENANCE:
  // - from_prompt: "It would be better to be parenthesized to:
  //   '3 \\left. \\left(- x + y\\right) \\right|_{\\substack{ x=1 }}'"
  //   => a low-precedence substituted expression must be grouped inside
  //      the substitution bar before multiplication prefixes the factor.
  // - from_code: V1 implements this by using
  //   parenthesize(expr, PRECEDENCE["Mul"], strict=True) in _print_Subs.
  claim
    <k> printMulFactor("3", printSubs(expr(40, "- x + y"), "x", "1"))
      => "3 \\left. \\left(- x + y\\right) \\right|_{\\substack{ x=1 }}" </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the parenthesized form is needed because the inner
  //   expression has additive precedence in a product context.
  // - from_default_domain: expressions whose precedence is lower than
  //   multiplication require parentheses when rendered as one factor body.
  claim
    <k> printSubs(expr(PREC, BODY), OLD, NEW)
      => "\\left. \\left(" +String BODY +String "\\right) \\right|_{\\substack{ "
         +String OLD +String "=" +String NEW +String " }}" </k>
    requires PREC <Int 50
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: latex(Subs(x*y, (x, y), (1, 2))) previously expected
  //   the body "x y" without added parentheses.
  // - from_code: strict=True means equal precedence is not parenthesized.
  claim
    <k> printSubs(expr(PREC, BODY), OLD, NEW)
      => "\\left. " +String BODY +String " \\right|_{\\substack{ "
         +String OLD +String "=" +String NEW +String " }}" </k>
    requires PREC >=Int 50
    [all-path]
endmodule
