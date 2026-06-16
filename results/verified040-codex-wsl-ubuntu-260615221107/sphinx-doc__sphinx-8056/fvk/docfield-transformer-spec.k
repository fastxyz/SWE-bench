requires "mini-docfields.k"

module DOCFIELD-TRANSFORMER-SPEC
  imports MINI-DOCFIELDS

  // SPEC-PROVENANCE:
  // - from_prompt: "x1, x2 : array_like, optional" is a valid NumPy
  //   parameter field and should render with both names and the optional type.
  // - from_code: pre-V2 transform split "x1, x2" as argtype "x1," and
  //   argname "x2" through the inline typed-field branch.
  // - obligation: comma-separated names remain one exact field argument.
  claim <k> transformParam(true, commaList("x1", "x2"), .TypeMap)
        => result("x1, x2", .TypeMap) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: rendered output must expose "array_like, optional".
  // - from_code: explicit :type fields attach by exact fieldarg key.
  // - obligation: once the comma name is preserved, its explicit type key
  //   matches and renders.
  claim <k> renderField(
              attachExplicitType(
                commaList("x1", "x2"),
                "array_like, optional",
                transformParam(true, commaList("x1", "x2"), .TypeMap)))
        => rendered("x1, x2", "array_like, optional") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: repo/doc/usage/restructuredtext/domains.rst documents
  //   ":param int priority:" for a single-word inline type.
  // - obligation: the V2 guard must not remove documented shorthand support.
  claim <k> transformParam(true, inlineTyped("str", "sender"), .TypeMap)
        => result("sender", type("sender", "str", .TypeMap)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_frame: non-typed grouped field arguments were not part of the
  //   reported bug and should keep the same argument text.
  claim <k> transformParam(false, commaList("x1", "x2"), .TypeMap)
        => result("x1, x2", .TypeMap) </k>
    [all-path]
endmodule
