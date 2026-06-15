requires "mini-python-string.k"

module TRIM-DOCSTRING-SPEC
  imports MINI-PYTHON-STRING
  imports BOOL
  imports STRING
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - E10: admindocs callsites pass __doc__ values, which may be None.
  // - PO-1: None returns the empty string.
  claim
    <k> trimDocstring(noneDoc) => "" </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E10: blank docstrings are tolerated by the existing helper contract.
  // - PO-1: all blank strings return the empty string.
  claim
    <k> trimDocstring(doc(S:String)) => "" </k>
    requires isBlankString(S)
    [all-path]

  // SPEC-PROVENANCE:
  // - E1-E4: first-line-summary docstrings are in scope; the first line must
  //   not determine the common margin for later lines.
  // - E6-E7: inspect.cleandoc implements the PEP 257 algorithm.
  // - PO-2, PO-3: non-empty cleanup uses cleanDocString and avoids local min().
  claim
    <k> trimDocstring(doc(S:String)) => cleanDocString(S) </k>
    requires notBool isBlankString(S)
    [all-path]

  // SPEC-PROVENANCE:
  // - E4-E7: cleanDocString is the PEP 257 cleanup operation. This claim is the
  //   explicit trusted-base boundary for the standard-library helper.
  // - PO-2, PO-3, PO-5.
  claim
    <k> pep257Clean(cleanDocString(S:String)) => true </k>
    requires notBool isBlankString(S)
    [all-path]

  // SPEC-PROVENANCE:
  // - E1, E2, E4, E9: dedenting prevents inserted admindocs text from becoming
  //   content of the injected default-role directive.
  // - PO-4.
  claim
    <k> directiveSafe(cleanDocString(S:String)) => true </k>
    requires notBool isBlankString(S)
    [all-path]

  // SPEC-PROVENANCE:
  // - E7-E8: existing Django-style docstrings with an empty first physical line
  //   remain governed by the same PEP 257 cleanup contract.
  // - PO-5.
  claim
    <k> leadingEmptyCompatible(cleanDocString(S:String)) => true </k>
    requires notBool isBlankString(S)
    [all-path]
endmodule
