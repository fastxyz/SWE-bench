requires "mini-python.k"

module FOWLKES-MALLOWS-SPEC
  imports MINI-PYTHON
  imports INT
  imports BOOL

  syntax Bool ::= validCounts(Int, Int, Int) [function]
  rule validCounts(TK:Int, PK:Int, QK:Int)
    => TK >=Int 0 andBool PK >=Int TK andBool QK >=Int TK

  // SPEC-PROVENANCE:
  // - from_prompt: "return tk / np.sqrt(pk * qk) ... overflow" =>
  //   do not form the integer product in the implementation expression.
  // - from_prompt: "Be able to calculate tk / np.sqrt(pk * qk)" =>
  //   expectedFmi is the public mathematical score.
  // - from_docs: FMI = TP / sqrt((TP + FP) * (TP + FN)).
  // - from_code: TK, PK, QK are the already-computed contingency counts.
  rule mulScore(sqrtScore(ratio(TK:Int, PK:Int)),
                sqrtScore(ratio(TK:Int, QK:Int)))
    => expectedFmi(TK, PK, QK)
    requires TK >Int 0 andBool validCounts(TK, PK, QK)
    [simplification]

  // Zero branch: no denominator is evaluated.
  claim
    <k> fmi(0, PK:Int, QK:Int) => zeroScore() </k>
    requires PK >=Int 0 andBool QK >=Int 0
    [all-path]

  // Nonzero branch: V1 expression is equivalent to the public FMI formula.
  claim
    <k> fmi(TK:Int, PK:Int, QK:Int) => expectedFmi(TK, PK, QK) </k>
    requires TK >Int 0 andBool validCounts(TK, PK, QK)
    [all-path]
endmodule
