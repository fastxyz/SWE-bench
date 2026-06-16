requires "mini-sympy-coth.k"

module COTH-EVAL-SPEC
  imports MINI-SYMPY-COTH

  // SPEC-PROVENANCE:
  // - from_prompt: ".subs on coth(log(tan(x))) errors for certain integral values"
  //   => evaluation must not raise NameError on this in-domain substitution path.
  // - from_prompt_hint: "`cotm` should be `cothm`"
  //   => the branch condition must read the local value assigned by coth(m).
  // - from_code: this claim starts after arg.is_Add, _peeloff_ipi(arg) = (x, m),
  //   and m is truthy; earlier branches are frame conditions outside this focused
  //   proof target.
  claim
    <k> cothEvalAddBranch(A:Expr, X:Expr, M:Expr) => .K </k>
    <cothm> NoExpr => ComplexInfinity </cothm>
    <result> NoExpr => Coth(X) </result>
    requires CothValue(M) ==K ComplexInfinity
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt_hint: the computed `cothm` value is the discriminator.
  // - from_code_comment: "else: # cothm == 0" supports the non-infinity path
  //   returning tanh(x) in this branch.
  claim
    <k> cothEvalAddBranch(A:Expr, X:Expr, M:Expr) => .K </k>
    <cothm> NoExpr => CothValue(M) </cothm>
    <result> NoExpr => Tanh(X) </result>
    requires CothValue(M) =/=K ComplexInfinity
    [all-path]
endmodule
