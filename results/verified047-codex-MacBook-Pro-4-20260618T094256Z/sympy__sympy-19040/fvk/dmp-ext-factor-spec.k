requires "mini-factor.k"

module DMP-EXT-FACTOR-SPEC
  imports MINI-FACTOR
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "Factor with extension=True drops a factor of y-1" =>
  //   extension factorization must preserve lower-variable factors.
  // - from_prompt: "factor(z) -> (x - 1)*(y - 1)" and
  //   "factor(z, extension=[I]) -> x - 1" describes the reported legacy
  //   symptom, not the intended postcondition.
  // - from_code: V1 uses dmp_primitive to split CONT from PRIM, factors CONT
  //   recursively, lifts it with dmp_include, then keeps dmp_trial_division as
  //   the multiplicity oracle.
  claim
    <k> dmpExtFactor(poly(1, 1,
                          YMINUS1 : 1 ; .FBag,
                          XMINUS1 : 1 ; .FBag))
      => factored(1,
                  YMINUS1 : 1 ;
                  XMINUS1 : 1 ;
                  .FBag)
      ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: same issue evidence as above.
  // - from_code: this diagnostic claim models the pre-V1 path, where only
  //   primitive/norm candidates reached trial division after dmp_sqf_part had
  //   removed main-variable content.
  // - conflicts: the result omits YMINUS1, matching the reported bug.
  claim
    <k> legacyExtFactor(poly(1, 1,
                             YMINUS1 : 1 ; .FBag,
                             XMINUS1 : 1 ; .FBag))
      => factored(1,
                  XMINUS1 : 1 ;
                  .FBag)
      ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: factor() documentation says factorization over an
  //   algebraic extension is selected with extension/domain options; it does
  //   not license dropping factors.
  // - from_code: when there is no main-variable content, V1's content path
  //   contributes no candidates and CC is 1, so the primitive/norm path is the
  //   same candidate source as legacy.
  claim
    <k> dmpExtFactor(poly(LC:Int, 1,
                          .FBag,
                          PRIM:FBag))
      => factored(LC, PRIM)
      ... </k>
    requires wfPoly(poly(LC, 1, .FBag, PRIM))
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: lower-variable factors such as y - 1 must remain factors
  //   even when the primitive part is constant in the main variable.
  // - from_code: V1 returns through dmp_trial_division immediately when the
  //   primitive part becomes constant after dmp_primitive.
  claim
    <k> dmpExtFactor(poly(LC:Int, CC:Int,
                          CONT:FBag,
                          .FBag))
      => factored(LC *Int CC, CONT)
      ... </k>
    requires wfPoly(poly(LC, CC, CONT, .FBag))
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: V1 multiplies the original leading coefficient by the
  //   coefficient returned from recursively factoring the content.
  // - from_prompt: complete factorization means both scalar coefficient and
  //   factor product reconstruct the original polynomial.
  claim
    <k> dmpExtFactor(poly(3, 5,
                          YMINUS1 : 2 ; .FBag,
                          XMINUS1 : 1 ; .FBag))
      => factored(15,
                  YMINUS1 : 2 ;
                  XMINUS1 : 1 ;
                  .FBag)
      ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the issue is one member of the general family "do not drop
  //   lower-variable factors during extension factorization".
  // - from_code: this summarizes V1's candidate-generation contract.
  // - proof-required: symbolic discharge needs the recursive bag coverage
  //   obligations named in dmp-ext-factor-obligations.k.
  claim
    <k> dmpExtFactor(poly(LC:Int, CC:Int, CONT:FBag, PRIM:FBag))
      => factored(LC *Int CC, bagUnion(CONT, PRIM))
      ... </k>
    requires wfPoly(poly(LC, CC, CONT, PRIM))
    [all-path]
endmodule
