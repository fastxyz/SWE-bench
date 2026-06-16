requires "mini-docfield.k"

module DOCFIELD-SPEC
  imports MINI-DOCFIELD

  // SPEC-PROVENANCE:
  // - from_issue: ":param dict(str, str) opc_meta:" is in domain.
  // - from_issue: expected parameter is "opc_meta"; legacy "str) opc_meta" is buggy.
  // - from_default_domain: Sphinx's inline typed field syntax is ":param type name:".
  claim <k> parseInline(words(TYPE:Words, NAME:String))
        => inline(joinWords(TYPE), NAME) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - concrete issue reproducer; distinguishes V1 from the first-split bug.
  claim <k> parseInline(words(words(word("dict(str,"), "str)"), "opc_meta"))
        => inline("dict(str, str)", "opc_meta") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from public test: ":param str name:" renders name "name" with type "str".
  claim <k> parseInline(words(word("str"), "name"))
        => inline("str", "name") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from current documented syntax: ":param name:" has no inline type.
  claim <k> parseInline(word("name"))
        => noInline("name") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from source/API audit: autodoc annotation merging must recognize the same
  //   parameter name for inline typed fields.
  claim <k> scanParam(words(TYPE:Words, NAME:String))
        => scanResult(true, true, NAME) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - concrete issue reproducer for autodoc annotation merging.
  claim <k> scanParam(words(words(word("dict(str,"), "str)"), "opc_meta"))
        => scanResult(true, true, "opc_meta") </k>
    [all-path]
endmodule
