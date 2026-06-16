requires "mini-optics-size.k"

module OPTICS-SIZE-SPEC
  imports MINI-OPTICS-SIZE
  imports INT

  // SPEC-PROVENANCE:
  // - from_prompt: "don't convert to int" and "NearestNeighbours class with a
  //   float ... raises" => fractional size normalization must produce an Int
  //   before neighbor-count use.
  // - from_prompt: "int(round(max(2, min_samples * n_samples)))" and docs
  //   "rounded to be at least 2" => the conversion is round(max(2, scaled)).
  // - from_code: this claim models the shared branch `if size <= 1`.
  claim
    <k> normalizeFractional(SCALED:FVal) => roundPy(maxF(two, SCALED)) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: absolute counts are already counts, so this audit does not
  //   change their value.
  // - from_code: absolute-count branch is frame behavior for this fix.
  claim
    <k> passAbsolute(I:Int) => I ... </k>
    requires I >Int 1
    [all-path]
endmodule
