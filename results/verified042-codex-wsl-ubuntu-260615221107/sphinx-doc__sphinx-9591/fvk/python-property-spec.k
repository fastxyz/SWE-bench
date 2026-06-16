requires "mini-python-domain.k"

module PY-PROPERTY-XREF-SPEC
  imports MINI-PYTHON-DOMAIN

  // SPEC-PROVENANCE:
  // - from_prompt: "Cross-references don't work in property's type annotations"
  //   => property type annotations must be represented by xref-capable nodes.
  // - from_prompt: "@property def end(self) -> Point"
  //   => the type token "Point" is an in-domain representative of T.
  // - from_code: _parse_annotation converts text annotation tokens to
  //   type_to_xref(...); PyProperty.handle_signature now calls it.
  claim
    <k> handlePropertyType(type(T:String)) => .K </k>
    <signode> S:Nodes => S descAnn(.Nodes txt(": ") xref(T)) </signode>
    requires T =/=String ""
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: no requested behavior change for untyped properties.
  // - from_code: the only branch touched by V1 is guarded by "if typ".
  claim
    <k> handlePropertyType(noType) => .K </k>
    <signode> S:Nodes => S </signode>
    [all-path]
endmodule
