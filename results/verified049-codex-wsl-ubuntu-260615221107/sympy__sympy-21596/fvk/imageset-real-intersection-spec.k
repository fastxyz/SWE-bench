requires "mini-sympy-sets.k"

module IMAGESET-REAL-INTERSECTION-SPEC
  imports MINI-SYMPY-SETS

  // SPEC-PROVENANCE:
  // - from_prompt: "S1.intersect(S2) Out {-1, 1}"
  // - from_math: (n - 1)*(n + 1) == 0 iff n in {-1, 1}
  claim <k> intersectReals(Image(IssueExpr, Integers)) => IssueResult </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "2 in S1.intersect(Reals) Out False"
  claim <k> contains(2, intersectReals(Image(IssueExpr, Integers))) => false </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: exact result {-1, 1}
  claim <k> contains(-1, intersectReals(Image(IssueExpr, Integers))) => true </k>
    [all-path]

  claim <k> contains(1, intersectReals(Image(IssueExpr, Integers))) => true </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: imageset(Lambda(n, 1/n), Integers).is_subset(Reals) is None
  // - from_default_domain: undefined denominator points are excluded from images.
  claim <k> intersectReals(Image(OneOverN, Integers)) => imageSet(OneOverN, NonZeroIntegers) </k>
    [all-path]
endmodule

