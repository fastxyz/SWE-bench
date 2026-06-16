requires "mini-sympy-evalf.k"

module FUNCTION-EVALF-SPEC
  imports MINI-SYMPY-EVALF

  // SPEC-PROVENANCE:
  // - E-001: "evalf does not call _imp_ recursively"
  // - E-003: "pass through the precision"
  claim [IMP-NUMERIC-RECURSES]:
    <k> evalImp(numericExpr(E:Expr), P:Int) => .K </k>
    <out> none => some(recEval(E, P)) </out>
    requires isNumber(E) andBool notBool hasAppliedUndef(recEval(E, P))
    [all-path]

  // SPEC-PROVENANCE:
  // - E-002: f(g(2)).evalf() must not remain f(g(2)).
  claim [ISSUE-COMPOSITION]:
    <k> evalImp(numericExpr(square(innerImpExpr(2))), P:Int) => .K </k>
    <out> none => some(evaled(16)) </out>
    requires P >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E-004: public test keeps f(x).evalf() as f(x).
  claim [SYMBOLIC-NONNUMERIC-NO-REWRITE]:
    <k> evalImp(symbolicExpr(symbolExpr), P:Int) => .K </k>
    <out> none => none </out>
    requires P >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E-005: preserve direct Float conversion behavior.
  claim [RAW-FLOAT-FALLBACK]:
    <k> evalImp(rawFloatable(I:Int), P:Int) => .K </k>
    <out> none => some(floatRaw(I, precToDps(P))) </out>
    requires P >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E-007: unresolved AppliedUndef after recursion is not success.
  claim [UNRESOLVED-NUMERIC-NO-SUCCESS]:
    <k> evalImp(numericExpr(unresolvedImpExpr(I:Int)), P:Int) => .K </k>
    <out> none => none </out>
    requires P >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E-006: unsupported or raising fallback cases return no value.
  claim [FAILURE-RETURNS-NONE-BAD]:
    <k> evalImp(badResult, P:Int) => .K </k>
    <out> none => none </out>
    requires P >Int 0
    [all-path]

  claim [FAILURE-RETURNS-NONE-RAISES]:
    <k> evalImp(impRaises, P:Int) => .K </k>
    <out> none => none </out>
    requires P >Int 0
    [all-path]
endmodule
