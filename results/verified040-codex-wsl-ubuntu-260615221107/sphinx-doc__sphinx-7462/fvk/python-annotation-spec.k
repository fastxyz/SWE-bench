requires "mini-python-annotation.k"

module PYTHON-ANNOTATION-SPEC
  imports MINI-PYTHON-ANNOTATION

  // SPEC-PROVENANCE:
  // - from_prompt: "`IndexError: pop from empty list` for empty tuple type annotation"
  //   => empty tuple is an in-domain boundary case.
  // - from_prompt: "generating `Tuple[()]` in docs"
  //   => preserve literal empty tuple delimiters.
  claim
    <k> render(Tuple(.Asts))
      => Punct("(") Punct(")") .Toks
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: `_parse_annotation("Callable[[int, int], int]")`
  //   => list delimiters are supported inside annotations.
  // - from_default_domain: the empty member of a delimiter list preserves both
  //   delimiters and has no separator to remove.
  claim
    <k> render(List(.Asts))
      => Punct("[") Punct("]") .Toks
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: `_parse_annotation("Tuple[int, int]")`
  //   => non-empty tuple slices remain comma-separated without extra parentheses.
  claim
    <k> render(Tuple(Name("int") , Name("str") , .Asts))
      => XRef("int") Punct(", ") XRef("str") .Toks
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: `_parse_annotation("Callable[[int, int], int]")`
  //   => non-empty list syntax keeps brackets and separators.
  claim
    <k> render(List(Name("int") , Name("str") , .Asts))
      => Punct("[") XRef("int") Punct(", ") XRef("str") Punct("]") .Toks
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: `Tuple[()]`
  //   => subscript integration wraps the empty tuple slice in `Tuple[...]`.
  claim
    <k> render(Subscript(Name("Tuple"), Tuple(Tuple(.Asts) , .Asts)))
      => XRef("Tuple") Punct("[") Punct("(") Punct(")") Punct("]") .Toks
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: Callable list syntax is supported.
  // - from_finding: V1 malformed the empty list slice by losing the opening
  //   bracket; V2 must preserve `[]`.
  claim
    <k> render(Subscript(Name("Callable"), Tuple(List(.Asts) , Name("int") , .Asts)))
      => XRef("Callable") Punct("[") Punct("[") Punct("]") Punct(", ")
         XRef("int") Punct("]") .Toks
    </k>
    [all-path]
endmodule
