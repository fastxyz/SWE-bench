requires "mini-sympy-mod.k"

module MOD-SPEC
  imports MINI-SYMPY-MOD

  // SPEC-PROVENANCE:
  // - from_prompt: "Unexpected PolynomialError when using simple subs" =>
  //   the PolynomialError from Mod's optional gcd extraction must not escape.
  // - from_prompt: "(Piecewise(...) / z) % 1 ... That should be fixed" =>
  //   Piecewise-triggered polynomial conversion failure falls back to symbolic
  //   Mod construction.
  // - from_code: the gcd extraction block is optional simplification after
  //   earlier direct Mod evaluations returned no result.
  claim
    <k> modEval(P:Expr, Q:Expr, gcdPolynomialError)
      => symbolicMod(P, Q, one)
    </k>
    requires notBool isZeroDivisor(Q)
     andBool notBool hasEarlyResult(P, Q)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/docstring: existing symbolic Mod simplifications should be
  //   preserved when gcd succeeds.
  claim
    <k> modEval(P:Expr, Q:Expr, gcdOk(G:Expr))
      => symbolicMod(P, Q, G)
    </k>
    requires notBool isZeroDivisor(Q)
     andBool notBool hasEarlyResult(P, Q)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: Mod.eval raises ZeroDivisionError for q.is_zero before gcd.
  // - from_Mod_docstring: modulo follows Python's modulo convention, including
  //   an error for zero divisor.
  claim
    <k> modEval(P:Expr, Q:Expr, GO:GcdOutcome)
      => zeroDivisionError
    </k>
    requires isZeroDivisor(Q)
    [all-path]
endmodule

