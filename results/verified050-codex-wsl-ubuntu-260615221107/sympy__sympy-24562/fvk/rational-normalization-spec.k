requires "mini-rational.k"

module RATIONAL-NORMALIZATION-SPEC
  imports MINI-RATIONAL

  // SPEC-PROVENANCE:
  // - from_prompt: "Rational('0.5', '100')" should be 1/200, not 1/100100.
  // - from_prompt: "Rational('0.5') / Rational('100')" is an expected route.
  // - from_hint: convert p and q with Rational(...) and combine integer fields.
  // - from_code: V1 stores p.q in qden, then uses q.p/q.q after Rational(q).
  claim
    <k> normalize(PN:Int, PD:Int, QN:Int, QD:Int, autoGcd, false) => .K </k>
    <result> noResult => canonical(PN *Int QD, PD *Int QN, autoGcd, false) </result>
    requires PD >Int 0 andBool QD >Int 0 andBool QN =/=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: reported concrete input should produce 1/200.
  // - conversion facts: Rational('0.5') = 1/2 and Rational('100') = 100/1.
  claim
    <k> normalize(1, 2, 100, 1, autoGcd, false) => .K </k>
    <result> noResult => rat(1, 200) </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: Rational(1, 0) and Rational(-1, 0) are ComplexInfinity.
  // - from_code: the zero-denominator branch remains below the patched block.
  claim
    <k> normalize(PN:Int, PD:Int, 0, QD:Int, autoGcd, false) => .K </k>
    <result> noResult => complexInfinity </result>
    requires PD >Int 0 andBool QD >Int 0 andBool PN =/=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: the zero-over-zero branch is controlled by _errdict["divide"].
  claim
    <k> normalize(0, PD:Int, 0, QD:Int, autoGcd, true) => .K </k>
    <result> noResult => valueError </result>
    requires PD >Int 0 andBool QD >Int 0
    [all-path]

  claim
    <k> normalize(0, PD:Int, 0, QD:Int, autoGcd, false) => .K </k>
    <result> noResult => nan </result>
    requires PD >Int 0 andBool QD >Int 0
    [all-path]
endmodule
