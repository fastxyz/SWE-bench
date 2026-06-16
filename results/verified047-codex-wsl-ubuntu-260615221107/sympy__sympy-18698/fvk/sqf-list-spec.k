requires "mini-sqf.k"

module SQF-LIST-SPEC
  imports MINI-SQF

  // SPEC-PROVENANCE:
  // - from_prompt: "combine factors of same multiplicity" => one entry per exponent
  // - from_code: _combine_factors scans factor pairs and multiplies equal exponents
  claim combine((x, 3) ; (y, 3) ; .Pairs)
    => (y * x, 3) ; .Pairs

  // SPEC-PROVENANCE:
  // - from_prompt: "one factor for each power" => unlike exponents stay distinct
  // - from_code: insert recurses past unequal exponents
  claim combine((x, 2) ; (y, 3) ; .Pairs)
    => (y, 3) ; (x, 2) ; .Pairs

  // SPEC-PROVENANCE:
  // - from_prompt: square-free methods are univariate; generator may be omitted only
  //   if there is no danger of confusion
  // - from_code: _sqf_list_should_combine requires one generator and a safe source
  claim shouldCombine(1, true) => true

  // SPEC-PROVENANCE:
  // - from_prompt: multivariate no-generator behavior is indeterminate/ambiguous
  // - from_code: V1 does not group when ambiguity remains
  claim shouldCombine(2, true) => false
endmodule
