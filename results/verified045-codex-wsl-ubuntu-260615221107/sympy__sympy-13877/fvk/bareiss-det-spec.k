requires "mini-sympy-bareiss.k"

module BAREISS-DET-SPEC
  imports MINI-SYMPY-BAREISS

  // SPEC-PROVENANCE:
  // - from_prompt: input matrices that contain nan should return nan immediately.
  // - from_code: V2 det() guard checks self.has(S.NaN) before method dispatch.
  claim
    <k> detGuard(nan, M:Vals) => nan </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: _find_pivot should use val.expand() before accepting val.
  // - semantic obligation: exprZero expands to zero and must not be returned.
  claim
    <k> findPivot(exprZero, .Vals) => noPivot </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: expansion-based zero detection must continue scanning.
  // - semantic obligation: later nonzero candidates remain available.
  claim
    <k> findPivot(exprZero, exprNonZero, .Vals) => pivot(1, exprNonZero) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - frame condition: non-expression truthy candidates keep old behavior.
  claim
    <k> findPivot(atomNonZero, .Vals) => pivot(0, atomNonZero) </k>
    [all-path]
endmodule

