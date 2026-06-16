requires "mini-python-annotation.k"

module PYTHON-ANNOTATION-SPEC
  imports MINI-PY-ANNOTATION

  // SPEC-PROVENANCE:
  // - from_prompt: "`Literal[True]` ... should be present ... should not trigger"
  // - obligation: True is visible text, not a py:class pending xref.
  claim <k> parseAnn("typing.Literal[True]") </k>
    => <k> XRef("typing.Literal") Punct("[") Text("True") Punct("]") .Tokens </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: reproduction includes typing.Literal[False].
  // - obligation: False is visible text, not a py:class pending xref.
  claim <k> parseAnn("typing.Literal[False]") </k>
    => <k> XRef("typing.Literal") Punct("[") Text("False") Punct("]") .Tokens </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "whatever literal value"
  // - from_code: signed numbers parse as ast.UnaryOp.
  claim <k> parseAnn("Literal[-1]") </k>
    => <k> XRef("Literal") Punct("[") Text("-1") Punct("]") .Tokens </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "whatever literal value"
  // - from_code: Literal stringification uses repr for string arguments.
  claim <k> parseAnn("Literal['x']") </k>
    => <k> XRef("Literal") Punct("[") Text("'x'") Punct("]") .Tokens </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "whatever literal value"
  // - from_code: fallback must cover Literal value text that the AST parser cannot parse.
  claim <k> parseAnn("Literal[<Color.RED: 1>]") </k>
    => <k> XRef("Literal") Punct("[") Text("<Color.RED: 1>") Punct("]") .Tokens </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: normal type annotation names are pending xrefs.
  claim <k> parseAnn("List[int]") </k>
    => <k> XRef("List") Punct("[") XRef("int") Punct("]") .Tokens </k>
    [all-path]
endmodule
