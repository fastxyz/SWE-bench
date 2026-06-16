requires "mini-roc.k"

module ROC-CURVE-SPEC
  imports MINI-ROC
  imports INT
  imports BOOL
  imports K-EQUAL

  syntax Bool ::= allProbFinite(Scores) [function]
  rule allProbFinite(.Scores) => true
  rule allProbFinite(finite(I:Int) ; TS:Scores)
    => (0 <=Int I andBool I <=Int 1 andBool allProbFinite(TS))
  rule allProbFinite(Inf ; TS:Scores) => false

  syntax Bool ::= scoreStrictlyAboveAll(Score, Scores) [function]
  rule scoreStrictlyAboveAll(Inf, TS:Scores) => true
  rule scoreStrictlyAboveAll(finite(T:Int), .Scores) => true
  rule scoreStrictlyAboveAll(finite(T:Int), finite(S:Int) ; TS:Scores)
    => (T >Int S andBool scoreStrictlyAboveAll(finite(T), TS))
  rule scoreStrictlyAboveAll(finite(T:Int), Inf ; TS:Scores) => false

  syntax Bool ::= rocProbabilityThresholds(Scores) [function]
  rule rocProbabilityThresholds(Inf ; TS:Scores) => allProbFinite(TS)
  rule rocProbabilityThresholds(finite(T:Int) ; TS:Scores) => false
  rule rocProbabilityThresholds(.Scores) => false

  // SPEC-PROVENANCE:
  // - from_prompt: "`+ 1` rule does not make sense" => do not fabricate a
  //   finite first threshold from max(y_score).
  // - from_docs: first threshold represents no instances being predicted.
  // - from_code: V1 prepends np.inf, modeled here as Inf.
  claim
    <k> prependStart(TS:Scores) => Inf ; TS </k>
    requires allProbFinite(TS)
    ensures rocProbabilityThresholds(Inf ; TS)
       andBool scoreStrictlyAboveAll(Inf, TS)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: probability scores are in [0, 1]; a finite threshold above
  //   1 is the reported bug.
  // - from_code: the old rule was thresholds[0] + 1.
  claim
    <k> legacyPrependPlusOne(finite(1), TS:Scores)
      => finite(2) ; finite(1) ; TS </k>
    requires allProbFinite(finite(1) ; TS)
    ensures notBool rocProbabilityThresholds(finite(2) ; finite(1) ; TS)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: clipping to 1 was proposed only as a possible workaround.
  // - from_docs: threshold i is applied using score >= thresholds[i].
  // - conflict: if an observed probability score is exactly 1, clipping does
  //   not represent "no instances predicted".
  claim
    <k> clipPrependOne(finite(1) ; TS:Scores)
      => finite(1) ; finite(1) ; TS </k>
    requires allProbFinite(finite(1) ; TS)
    ensures notBool scoreStrictlyAboveAll(finite(1), finite(1) ; TS)
    [all-path]
endmodule
