requires "mini-autodoc.k"

module AUTODOC-FILTER-SPEC
  imports MINI-AUTODOC

  // SPEC-PROVENANCE:
  // - from_prompt: "_foo = None  #: :meta public:" with automodule :members:
  //   => a private-looking module variable with attribute-comment public metadata is shown.
  // - from_code: attr_docs presence routes through the documented-attribute branch.
  claim <k> filterMember(true, noneMeta, true, publicMeta,
                         true, false, false, false, false,
                         false, false, false, false)
        => decision(true, true) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: ":meta private:" makes a member private.
  // - from_code: no :private-members: admission means a private documented attribute is skipped.
  claim <k> filterMember(false, noneMeta, true, privateMeta,
                         true, false, false, false, false,
                         false, false, false, false)
        => decision(false, true) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: add_content() uses attribute documentation as the variable's documentation.
  // - proof-finding: V1 merged attr public with doc private, leaving both markers and preserving
  //   private precedence from the unrelated runtime docstring.
  // - obligation: attribute-comment visibility metadata controls documented variable visibility.
  claim <k> filterMember(true, privateMeta, true, publicMeta,
                         true, false, false, false, false,
                         true, false, false, false)
        => decision(true, true) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests/docs: docstring public metadata still works when attribute docs have
  //   no visibility marker.
  claim <k> filterMember(true, publicMeta, true, noneMeta,
                         true, false, false, false, false,
                         true, false, false, false)
        => decision(true, true) </k>
    [all-path]
endmodule
