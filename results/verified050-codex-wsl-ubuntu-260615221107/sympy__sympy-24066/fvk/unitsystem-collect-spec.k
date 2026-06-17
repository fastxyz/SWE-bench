// Constructed, not machine-checked.
// Claims for the reduced collector model in mini-sympy-units.k.

requires "mini-sympy-units.k"

module UNITSYSTEM-COLLECT-SPEC
  imports MINI-SYMPY-UNITS

  // SPEC-PROVENANCE:
  // - from_prompt: second/(ohm*farad) is dimensionless under SI.
  // - obligation: exp(second/(ohm*farad)) collects with Dimension(1).
  // CLAIM: FUNCTION-DIMENSIONLESS-RC
  claim
    <k> collect(exp(rcExpr)) => res(expF(FRC), D1) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: 100 + exp(second/(ohm*farad)) must not raise ValueError.
  // - obligation: addition reaches a normal dimensionless result.
  // CLAIM: ADD-REPORTED-EXPR
  claim
    <k> collect(add(num100, exp(rcExpr))) => res(addF(N100, expF(FRC)), D1) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: incompatible additions raise ValueError.
  // - obligation: non-equivalent dimensions still reject.
  // CLAIM: ADD-INCOMPATIBLE-DIMS
  claim
    <k> collect(add(num100, exp(lenExpr))) => err("incompatible-dimensions") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_fvk_finding: TypeError/unsupported dimension analysis is not proof
  //   of dimensionlessness.
  // - obligation: unsupported dimensions are not normalized in function results.
  // CLAIM: FUNCTION-UNSUPPORTED-DIM
  claim
    <k> collect(exp(unsupportedExpr)) => res(expF(FUNSUPPORTED), DUNSUPPORTED) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_fvk_finding: unsupported equivalence analysis should preserve the
  //   collector's incompatible-addition rejection behavior.
  // CLAIM: ADD-UNSUPPORTED-DIM
  claim
    <k> collect(add(num100, exp(unsupportedExpr))) => err("incompatible-dimensions") </k>
    [all-path]
endmodule
