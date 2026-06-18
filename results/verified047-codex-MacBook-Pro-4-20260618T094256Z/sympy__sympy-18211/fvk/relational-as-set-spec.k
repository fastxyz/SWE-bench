requires "mini-sympy-relational.k"

module RELATIONAL-AS-SET-SPEC
  imports MINI-SYMPY-RELATIONAL

  // SPEC-PROVENANCE:
  // - from_prompt: "ConditionSet(n, Eq(n*cos(n) - 3*sin(n), 0), Reals)"
  //   => unsolved univariate relationals must be representable as real sets.
  // - from_code: Relational._eval_as_set calls solve_univariate_inequality
  //   with relational=False and returns the resulting set on success.
  // - from_docs_or_tests: existing relational as_set tests cover exact solved
  //   results such as Eq(x, 0).as_set() == FiniteSet(0).
  // - conflicts: none for exact solver results.
  claim
    <k> relEvalAsSet(rel(X:Sym, P:Period, exact(S:Set)))
      => ret(S) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "`solveset` raises `NotImplementedError` instead of
  //   returning `ConditionSet`" and "probably a `ConditionSet` should be
  //   returned".
  // - from_prompt: the obvious result shown is ConditionSet(n, Eq(...), Reals).
  // - from_code: solve_univariate_inequality documents NotImplementedError
  //   when solver limitations prevent a solution.
  // - conflicts: V0 leaked raisesNotImplemented; V1 catches it.
  claim
    <k> relEvalAsSet(rel(X:Sym, P:Period, cannotSolve))
      => ret(conditionSet(X, rel(X, P, cannotSolve), reals)) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: Boolean.as_set examples rewrite Eq(x, 0), x > 0,
  //   and x**2 >= 4 into concrete real sets.
  // - from_code: Boolean.as_set delegates non-periodic univariate relationals
  //   to _eval_as_set.
  // - conflicts: none; this is the regression frame for solved relationals.
  claim
    <k> boolAsSet(rel(X:Sym, nonPeriodic, exact(S:Set)))
      => ret(S) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: Eq(n*cos(n) - 3*sin(n), 0).as_set() should return a
  //   ConditionSet over Reals instead of NotImplementedError.
  // - from_code: the reported expression has one free symbol and reaches
  //   Relational._eval_as_set when no periodic replacement applies.
  // - conflicts: V0 leaked the solver failure; V1 returns the ConditionSet.
  claim
    <k> boolAsSet(rel(X:Sym, nonPeriodic, cannotSolve))
      => ret(conditionSet(X, rel(X, nonPeriodic, cannotSolve), reals)) ... </k>
    [all-path]
endmodule
