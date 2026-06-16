requires "mini-sympy-mod.k"

module MINI-SYMPY-MOD-SPEC
  imports MINI-SYMPY-MOD

  // SPEC-PROVENANCE:
  // - from_prompt: "`Mod(3*i, 2)` should reduce to `Mod(i, 2)`"
  //   => integer coefficient reduction must happen on the default Mod
  //      construction path.
  // - from_docs: Mod uses Python's modulo convention: the remainder has the
  //   same sign as the divisor.
  // - from_default_domain: for integers C, Q, T with Q != 0,
  //   C == Q * floor(C / Q) + (C % Q), so multiplying by T preserves
  //   congruence modulo Q.
  // - from_code: the V1 branch is guarded by integer coefficient, integer
  //   divisor, no remaining divisor factor, and integer tail.
  claim
    <k> checkEquivalent(C:Int, T:Int, Q:Int) => true </k>
    requires Q =/=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the reported instance is C=3, T=i, Q=2.
  // - from_code: after coefficient extraction, the branch returns a Mod whose
  //   dividend is (3 % 2) * i, i.e. i.
  claim
    <k> reduceCoeff(3, T:Int, 2, true, true, true)
      => modExpr(T, 2)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_hint: `Mod(e/2, 2)` for an even symbol e must remain unevaluated
  //   because e/2 may be odd.
  // - from_code: a rational coefficient such as 1/2 means the integer
  //   coefficient guard is false, so the V1 branch is not taken.
  claim
    <k> reduceCoeff(C:Int, T:Int, Q:Int, false, true, true)
      => unchanged
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_hint: float and symbolic-divisor corner cases must not be changed
  //   by the coefficient fix.
  // - from_code: if the divisor has a remaining symbolic factor, the
  //   divisor-plain guard is false, so the V1 branch is not taken.
  claim
    <k> reduceCoeff(C:Int, T:Int, Q:Int, true, false, true)
      => unchanged
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_intent: reducing a numeric coefficient modulo Q is only valid when
  //   the remaining tail is known integer.
  // - from_code: non-integer or unknown-integer tails keep the legacy path.
  claim
    <k> reduceCoeff(C:Int, T:Int, Q:Int, true, true, false)
      => unchanged
    </k>
    [all-path]
endmodule
