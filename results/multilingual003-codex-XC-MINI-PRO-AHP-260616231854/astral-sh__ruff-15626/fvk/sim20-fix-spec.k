requires "mini-fix-applicability.k"

module SIM20-FIX-SPEC
  imports MINI-FIX-APPLICABILITY

  // SPEC-PROVENANCE:
  // - from_prompt: "SIM201 and SIM202 fixes should be marked unsafe" =>
  //   unsafe is the default when operand comparison result is not known bool.
  // - from_prompt: "still safe when the operands are of types whose __eq__
  //   and __ne__ are known to return bool" =>
  //   safe requires both operands to be known bool-comparison operands.
  claim
    <k> fixApplicability(RULE:Rule, LEFT:Evidence, RIGHT:Evidence) => safe </k>
    requires known(LEFT) ==Bool true andBool known(RIGHT) ==Bool true
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "__eq__ and __ne__ may return any type, not just bool" =>
  //   any unknown operand must keep the fix unsafe.
  claim
    <k> fixApplicability(RULE:Rule, LEFT:Evidence, RIGHT:Evidence) => unsafe </k>
    requires notBool (known(LEFT) ==Bool true andBool known(RIGHT) ==Bool true)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "import numpy as np; a = np.array([0]); b = np.array([1])"
  //   with changed behavior after --fix =>
  //   NumPy array constructor calls are unknown calls in this abstraction.
  claim
    <k> fixApplicability(RULE:Rule, unknownCall, unknownCall) => unsafe </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code_audit: a name with an initializer must be classified from the
  //   initializer before annotation-only semantic helpers are used.
  claim
    <k> fixApplicability(RULE:Rule, unknownCall, semanticKnown) => unsafe </k>
    [all-path]
endmodule
