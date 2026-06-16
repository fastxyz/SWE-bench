requires "mini-sympy-as-set.k"

module RELATIONAL-AS-SET-SPEC
  imports MINI-SYMPY-AS-SET

  // SPEC-PROVENANCE:
  // - from_public_tests: "Eq(x, 0).as_set() == FiniteSet(0)" and interval
  //   assertions for inequalities => solved univariate relationals preserve
  //   the solver-produced set.
  // - from_code: Relational._eval_as_set delegates to
  //   solve_univariate_inequality(self, x, relational=False).
  // CLAIM: AS-SET-SOLVED
  claim
    <k> evalAsSet(rel(X:Id), solved(S:Set)) => .K </k>
    <result> noSet => some(S) </result>
    <exception> none => none </exception>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "NotImplementedError" from
  //   Eq(n*cos(n) - 3*sin(n), 0).as_set() is the reported bug.
  // - from_prompt: "ConditionSet(n, Eq(n*cos(n) - 3*sin(n), 0), Reals)" is
  //   the stated obvious result => solver incompleteness in this as_set path
  //   must become a real-domain ConditionSet preserving the relation.
  // - from_public_hint: catch NotImplementedError from
  //   solve_univariate_inequality and return ConditionSet(x, self, S.Reals).
  // CLAIM: AS-SET-NOTIMPLEMENTED
  claim
    <k> evalAsSet(rel(X:Id), notImplemented) => .K </k>
    <result> noSet => some(conditionSet(X, rel(X), Reals)) </result>
    <exception> none => none </exception>
    [all-path]
endmodule
