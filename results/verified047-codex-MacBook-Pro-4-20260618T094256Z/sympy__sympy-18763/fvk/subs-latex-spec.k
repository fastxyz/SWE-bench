requires "mini-latex-printer.k"

module SUBS-LATEX-SPEC
  imports MINI-LATEX-PRINTER
  imports INT
  imports BOOL

  // CLAIM PAREN-LOW-STRICT
  // SPEC-PROVENANCE:
  // - from_prompt: "It would be better to be parenthesized to:
  //   '3 \\left. \\left(- x + y\\right) \\right|_{\\substack{ x=1 }}'"
  //   => additive Subs expressions must be grouped when rendered before the
  //      substitution bar in a multiplicative context.
  // - from_code: LatexPrinter.parenthesize wraps when
  //   precedence_traditional(item) < PRECEDENCE["Mul"] under strict=True.
  // - conflicts: none for the candidate V1 code.
  claim
    <k> parenthesize(E:Expr, 50, true) => paren(render(E)) ... </k>
    requires prec(E) <Int 50
    [all-path]

  // CLAIM PAREN-NONLOW-STRICT
  // SPEC-PROVENANCE:
  // - from_docs_or_tests: "latex(Subs(x*y, (x, y), (1, 2))) ==
  //   '\\left. x y \\right|_{\\substack{ x=1\\\\ y=2 }}'"
  //   => multiplicative Subs expressions must not gain extra parentheses.
  // - from_code: strict=True avoids wrapping expressions with precedence equal
  //   to PRECEDENCE["Mul"].
  // - conflicts: none for the candidate V1 code.
  claim
    <k> parenthesize(E:Expr, 50, true) => render(E) ... </k>
    requires notBool (prec(E) <Int 50)
    [all-path]

  // CLAIM SUBS-LOW-PRECEDENCE
  // SPEC-PROVENANCE:
  // - from_prompt: desired output places "\\left(- x + y\\right)" inside
  //   "\\left. ... \\right|".
  // - from_code: _print_Subs calls parenthesize(expr, PRECEDENCE["Mul"],
  //   strict=True) and preserves the printed substitution assignments.
  // - conflicts: none for the candidate V1 code.
  claim
    <k> printSubs(E:Expr, A:Assigns) => subsTex(paren(render(E)), A) ... </k>
    requires prec(E) <Int 50
    [all-path]

  // CLAIM SUBS-NONLOW-PRECEDENCE
  // SPEC-PROVENANCE:
  // - from_docs_or_tests: existing non-additive Subs(x*y, ...) output has no
  //   parenthesized expression before the bar.
  // - from_code: strict parenthesize leaves precedence >= Mul expressions
  //   unchanged.
  // - conflicts: none for the candidate V1 code.
  claim
    <k> printSubs(E:Expr, A:Assigns) => subsTex(render(E), A) ... </k>
    requires notBool (prec(E) <Int 50)
    [all-path]

  // CLAIM ISSUE-EXAMPLE
  // SPEC-PROVENANCE:
  // - from_prompt: concrete issue input is 3*Subs(-x+y, (x,), (1,)).
  // - from_prompt: desired shape is
  //   "3 \\left. \\left(- x + y\\right) \\right|_{...}".
  // - from_code: printMulWithCoeff models the outer numeric multiplication
  //   and delegates the Subs factor to printSubs.
  // - conflicts: none for the candidate V1 code.
  claim
    <k> printMulWithCoeff(3, addExpr, assignOne)
      => mulTex(numTex(3), subsTex(paren(rawAdd), assignOne)) ... </k>
    [all-path]

  // CLAIM LEGACY-COUNTEREXAMPLE-DIAGNOSTIC
  // SPEC-PROVENANCE:
  // - from_prompt: reported buggy output is
  //   "3 \\left. - x + y \\right|_{\\substack{ x=1 }}".
  // - from_code: the pre-V1 behavior printed the Subs expression directly.
  // - conflicts: this is intentionally SUSPECT legacy behavior and is included
  //   only to localize the bug mechanism.
  claim
    <k> printMulWithCoeffLegacy(3, addExpr, assignOne)
      => mulTex(numTex(3), subsTex(rawAdd, assignOne)) ... </k>
    [all-path]
endmodule
