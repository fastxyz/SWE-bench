requires "mini-monomials.k"

module ITERMONOMIALS-SPEC
  imports MINI-MONOMIALS

  // SPEC-PROVENANCE:
  // - E3: integer min/max mode is specified by total degree.
  // - E5: the fix changes the lower-bound filter from max exponent to sum.
  claim
    <k> acceptByTotal(CS:ExpCounts, MIN:Int) => true </k>
    requires MIN >=Int 0
     andBool totalDegree(CS) >=Int MIN
    [all-path]

  // SPEC-PROVENANCE:
  // - E3: candidates below the total-degree lower bound must not be yielded.
  claim
    <k> acceptByTotal(CS:ExpCounts, MIN:Int) => false </k>
    requires MIN >=Int 0
     andBool totalDegree(CS) <Int MIN
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: mixed monomials such as x1*x2**2 are required at degree 3.
  claim
    <k> acceptByTotal(counts(ListItem(1) ListItem(2) ListItem(0) .List), 3) => true </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E5: the pre-fix max-exponent predicate rejects the required mixed candidate.
  claim
    <k> acceptByMax(counts(ListItem(1) ListItem(2) ListItem(0) .List), 3) => false </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E8: the unit monomial has total degree 0, so it is yielded only for min 0.
  claim
    <k> unitBranchYieldsOne(MIN:Int) => (MIN ==Int 0) </k>
    requires MIN >=Int 0
    [all-path]
endmodule
