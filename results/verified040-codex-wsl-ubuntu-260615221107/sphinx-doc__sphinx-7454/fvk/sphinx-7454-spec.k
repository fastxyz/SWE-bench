requires "mini-sphinx-annotation.k"

module SPHINX-7454-SPEC
  imports MINI-SPHINX-ANNOTATION
  imports STRING

  // SPEC-PROVENANCE:
  // - from_prompt: "None in a type hint links to the documentation for the
  //   None singleton regardless of whether 'description' or 'signature' mode
  //   is used." => direct signature annotation None must resolve as a Python
  //   object-role reference, not as a Python class-role reference.
  // - from_code: repo/sphinx/domains/python.py::_parse_annotation calls
  //   make_xref for parsed text tokens and for the SyntaxError fallback.
  claim
    <k> makeXref("None") => xref(objRole, "None") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: f2() -> int links in signature mode, so non-None type
  //   annotations retain the existing class-role behavior.
  // - from_code: V1 changes only the exact text "None".
  claim
    <k> makeXref(T:String) => xref(classRole, T) </k>
    requires T =/=String "None"
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: with intersphinx, signature-mode None should become the
  //   same external Python docs link that description mode produces.
  // - from_code: intersphinx missing-reference handling runs before the
  //   Python built-in fallback, and the py:obj role expands to Python object
  //   inventory types including data/constants.
  claim
    <k> signatureLink(hasPyObjRoleNone, "None")
     => external("https://docs.python.org/3/library/constants.html#None")
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the bug is specific to None; f2() -> int must keep linking
  //   as before.
  // - from_code: any token other than "None" uses classRole.
  claim
    <k> makeXref("int") => xref(classRole, "int") </k>
    [all-path]
endmodule
