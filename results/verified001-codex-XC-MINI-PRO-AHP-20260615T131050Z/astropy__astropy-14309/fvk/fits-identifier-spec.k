requires "mini-fits-identifier.k"

module FITS-IDENTIFIER-SPEC
  imports MINI-FITS-IDENTIFIER

  // SPEC-PROVENANCE:
  // - from_prompt: identify_format("write", Table, "bububu.ecsv", None, [], {})
  //   must not raise IndexError.
  // - from_prompt: non-FITS filepath with no object argument is a FITS non-match.
  // Claim: FITS-NONEXT-EMPTY-ARGS
  claim
    <k> isFits(nonFitsPath, noFile, noArgs) => false </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code_public_behavior: existing FITS suffix list is a positive match.
  // Claim: FITS-SUFFIX-PATH
  claim
    <k> isFits(fitsPath, noFile, noArgs) => true </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docstring: file object content can identify FITS.
  // Claim: FITS-FILEOBJ-SIGNATURE
  claim
    <k> isFits(noPath, fitsSignatureFile, noArgs) => true </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docstring: non-FITS file object content is a non-match.
  // Claim: FITS-FILEOBJ-NONSIGNATURE
  claim
    <k> isFits(fitsPath, nonFitsSignatureFile, arg(hduArg, noArgs)) => false </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code_public_behavior: accepted FITS HDU objects are positive matches.
  // Claim: FITS-HDU-ARG
  claim
    <k> isFits(noPath, noFile, arg(hduArg, noArgs)) => true </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docstring: non-HDU object without file/path evidence is a non-match.
  // Claim: FITS-NONHDU-ARG
  claim
    <k> isFits(nonFitsPath, noFile, arg(nonHduArg, noArgs)) => false </k>
    [all-path]
endmodule
