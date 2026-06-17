requires "mini-hnf.k"

module HNF-SPEC
  imports MINI-HNF
  imports K-EQUAL
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - E1/E3/E5: HNF must preserve the input matrix rank and column module.
  // - E6: the implementation uses unimodular column operations and returns a
  //   suffix, so proof obligations PO3-PO6 connect the code to this claim.
  claim
    <k> hermite(A:Matrix) => H:Matrix </k>
    requires isZZMatrix(A)
    ensures rows(H) ==Int rows(A)
      andBool cols(H) ==Int rank(A)
      andBool isColumnHNF(H)
      andBool sameColumnModule(A, H)
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E4: the public issue expects the transformed matrix to retain two
  //   columns so the row-style flip/transpose result keeps both rows.
  claim
    <k> hermite(issueB()) => issueH() </k>
    requires isZZMatrix(issueB())
    ensures rows(issueH()) ==Int 3
      andBool cols(issueH()) ==Int 2
      andBool rank(issueB()) ==Int 2
      andBool sameColumnModule(issueB(), issueH())
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E7: a rank-positive tall matrix must not return zero columns merely
  //   because its nonzero row is above the bottom n-row window.
  claim
    <k> hermite(rankDefTop()) => H:Matrix </k>
    requires isZZMatrix(rankDefTop())
      andBool rows(rankDefTop()) ==Int 3
      andBool cols(rankDefTop()) ==Int 2
      andBool rank(rankDefTop()) ==Int 1
    ensures rows(H) ==Int 3
      andBool cols(H) ==Int 1
      andBool sameColumnModule(rankDefTop(), H)
    [all-path]
endmodule
