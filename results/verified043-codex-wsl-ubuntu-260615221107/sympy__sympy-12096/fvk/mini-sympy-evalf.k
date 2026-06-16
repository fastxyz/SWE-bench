module MINI-SYMPY-EVALF-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Expr ::= intExpr(Int)
                | symbolExpr
                | innerImpExpr(Int)
                | unresolvedImpExpr(Int)
                | square(Expr)
                | evaled(Int)

  syntax ImpResult ::= numericExpr(Expr)
                     | symbolicExpr(Expr)
                     | rawFloatable(Int)
                     | badResult
                     | impRaises

  syntax Outcome ::= some(Expr) | none

  syntax KItem ::= evalImp(ImpResult, Int)

  syntax Bool ::= isNumber(Expr) [function]
                | hasAppliedUndef(Expr) [function]
  syntax Expr ::= recEval(Expr, Int) [function]
                | recEvalSquare(Expr, Int) [function]
                | floatRaw(Int, Int) [function]
  syntax Int ::= precToDps(Int) [function]

  syntax KResult ::= Outcome | Expr
endmodule

module MINI-SYMPY-EVALF
  imports MINI-SYMPY-EVALF-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:KItem </k>
    <out> none </out>

  // SPEC-PROVENANCE:
  // - from_prompt: "evalf does not call _imp_ recursively" => numeric _imp_
  //   results are evaluated by recEval at the same binary precision.
  rule
    <k> evalImp(numericExpr(E:Expr), P:Int) => .K </k>
    <out> _ => some(recEval(E, P)) </out>
    requires isNumber(E) andBool notBool hasAppliedUndef(recEval(E, P))

  // SPEC-PROVENANCE:
  // - from_legacy_code: unresolved applied undefined functions are not
  //   successful numeric evaluation results.
  rule
    <k> evalImp(numericExpr(E:Expr), P:Int) => .K </k>
    <out> _ => none </out>
    requires isNumber(E) andBool hasAppliedUndef(recEval(E, P))

  // SPEC-PROVENANCE:
  // - from_public_test: "f(x).evalf() == f(x)" => nonnumeric symbolic
  //   implementation results do not become symbolic rewrites.
  rule
    <k> evalImp(symbolicExpr(E:Expr), P:Int) => .K </k>
    <out> _ => none </out>
    requires notBool isNumber(E)

  // SPEC-PROVENANCE:
  // - from_legacy_code: "Float(self._imp_(*self.args), prec)" => keep the
  //   direct Float-compatible fallback, using public decimal precision.
  rule
    <k> evalImp(rawFloatable(I:Int), P:Int) => .K </k>
    <out> _ => some(floatRaw(I, precToDps(P))) </out>

  // SPEC-PROVENANCE:
  // - from_legacy_code: caught AttributeError/TypeError/ValueError => no value.
  rule <k> evalImp(badResult, P:Int) => .K </k> <out> _ => none </out>
  rule <k> evalImp(impRaises, P:Int) => .K </k> <out> _ => none </out>

  rule isNumber(intExpr(I:Int)) => true
  rule isNumber(innerImpExpr(I:Int)) => true
  rule isNumber(unresolvedImpExpr(I:Int)) => true
  rule isNumber(square(E:Expr)) => isNumber(E)
  rule isNumber(evaled(I:Int)) => true
  rule isNumber(symbolExpr) => false

  rule hasAppliedUndef(intExpr(I:Int)) => false
  rule hasAppliedUndef(innerImpExpr(I:Int)) => false
  rule hasAppliedUndef(unresolvedImpExpr(I:Int)) => true
  rule hasAppliedUndef(square(E:Expr)) => hasAppliedUndef(E)
  rule hasAppliedUndef(evaled(I:Int)) => false
  rule hasAppliedUndef(symbolExpr) => false

  rule recEval(intExpr(I:Int), P:Int) => evaled(I)
  rule recEval(innerImpExpr(I:Int), P:Int) => evaled(I *Int 2)
  rule recEval(unresolvedImpExpr(I:Int), P:Int) => unresolvedImpExpr(I)
  rule recEval(square(E:Expr), P:Int) => recEvalSquare(recEval(E, P), P)
  rule recEvalSquare(evaled(I:Int), P:Int) => evaled(I *Int I)
  rule recEvalSquare(unresolvedImpExpr(I:Int), P:Int) => square(unresolvedImpExpr(I))
endmodule
