// FVK artifact for scikit-learn__scikit-learn-15100.
// Constructed, not machine-checked.

requires "mini-python-unicode.k"

module STRIP-ACCENTS-UNICODE-SPEC
  imports MINI-PYTHON-UNICODE
  imports BOOL

  // SPEC-PROVENANCE:
  // - E1/E5/E6: Unicode accent stripping uses NFKD normalization.
  // - E4: public hint supports removing the early return.
  // - O-2/O-3/O-5: result is exactly removeCombining(nfkd(S)).
  claim
    <k> stripAccentsUnicode(S:UString) => .K </k>
    <result> .K => removeCombining(nfkd(S)) </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: chr(241) and chr(110)+chr(771) both produce chr(110).
  // - O-6: precomposed n-with-tilde case.
  claim
    <k> stripAccentsUnicode(precomposedNTilde()) => .K </k>
    <result> .K => plainN() </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2/E3: already-NFKD decomposed input must still be filtered.
  // - O-4/O-6: decomposed n-with-tilde case.
  claim
    <k> stripAccentsUnicode(decomposedNTilde()) => .K </k>
    <result> .K => plainN() </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E6: stripping removes accents, represented as combining marks.
  // - O-5: the result is combining-free in the abstract model.
  claim
    <k> stripAccentsUnicode(S:UString) => .K </k>
    <result> .K => R:UString </result>
    ensures isCombiningFree(R)
    [all-path]
endmodule

