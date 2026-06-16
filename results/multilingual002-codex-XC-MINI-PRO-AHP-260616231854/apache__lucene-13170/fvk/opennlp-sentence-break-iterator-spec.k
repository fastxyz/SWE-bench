requires "mini-java-break-iterator.k"

module OPENNLP-SENTENCE-BREAK-ITERATOR-SPEC
  imports MINI-JAVA-BREAK-ITERATOR
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_problem: length-two pre-fix currentSentence becomes 1 and can trigger
  //   ArrayIndexOutOfBoundsException in moveToSentenceAt.
  // - from_code: pre-fix midpoint was sentenceStarts.length / 2.
  // CLAIM: PRE_FIX_COUNTEREXAMPLE
  claim
    <k> precedingOld(2) => arrayIndexOutOfBounds ... </k>
    [one-path]

  // SPEC-PROVENANCE:
  // - from_problem: preceding should use (sentenceStarts.length - 1) / 2, like following.
  // - from_problem: the length-two path must no longer raise ArrayIndexOutOfBoundsException.
  // - from_default_domain: valid Java array indices are 0..N-1.
  // CLAIM: PRECEDING_V1_SAFE
  claim
    <k> precedingV1(N:Int) => done ... </k>
    requires N >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: moveToSentenceAt reads sentenceStarts[currentSentence + 1] in each
  //   non-base frame before taking the right branch.
  // - from_proof: every caller/circular recursive frame must preserve Cur < Max when
  //   Min < Max, so Cur + 1 <= Max < N.
  // CLAIM: MOVE_SAFE
  claim
    <k> move(N:Int, Min:Int, Cur:Int, Max:Int) => done ... </k>
    requires 0 <=Int Min
      andBool Min <=Int Cur
      andBool Cur <=Int Max
      andBool Max <Int N
      andBool (Min ==Int Max orBool Cur <Int Max)
    [all-path]
endmodule
