requires "mini-dense-polys.k"

module CLEAR-DENOMS-SPEC
  imports MINI-DENSE-POLYS
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "unstripped DMP" and `DMP([EX(0)])` should be `DMP([])`.
  // - from_code: V1 returns dup_strip after dup_mul_ground.
  // - from_default_domain: stripping leading zeros preserves dense polynomial value.
  claim
    <k> dupClearDenoms(F:Poly) => pair(C:Coeff, R:Poly) </k>
    ensures C ==K dupCommon(F, one)
      andBool R ==K dupStrip(dupMulGround(F, C))
      andBool canonical(R)
    [all-path]

  // SPEC-PROVENANCE:
  // - concrete symbolic model of the issue: a coefficient not initially
  //   recognized as zero has denominator denLatentZero; multiplying by that
  //   denominator simplifies it to zero.
  claim
    <k> dupClearDenoms(cons(latentZero, .Poly))
        => pair(denLatentZero, .Poly) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: downstream dense methods require canonical zero.
  // - from_code: V1 uses recursive strip for dmp_clear_denoms.
  // - proof finding F2: top-level dmp_strip alone cannot see an inner [0].
  claim
    <k> dmpClearDenoms(F:DPoly) => dpair(C:Coeff, R:DPoly) </k>
    ensures C ==K dmpCommon(F, one)
      andBool R ==K recStrip(dmpMulGround(F, C))
      andBool dcanonical(R)
    [all-path]

  // SPEC-PROVENANCE:
  // - recursive analogue of the reported univariate bad representation.
  claim
    <k> dmpClearDenoms(dcons(leaf(cons(latentZero, .Poly)), .DPoly))
        => dpair(denLatentZero, .DPoly) </k>
    [all-path]
endmodule
