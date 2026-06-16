requires "mini-django-bulk-update.k"

module BULK-UPDATE-SPEC
  imports MINI-DJANGO-BULK-UPDATE

  // SPEC-PROVENANCE:
  // - from_prompt: "bulk_update() does not work with plain F('...') expressions"
  //   => a plain F() assigned to a model field is in-domain for bulk_update().
  // - from_prompt: "The created SQL contains the string repr of F(), instead of resolving to the column name"
  //   => F("name") must resolve to a column reference, not to Param("F(name)").
  // - from_hint: "we should check resolve_expression like elsewhere"
  //   => the branch discriminator is resolve_expression, not Expression subclassing.
  claim
    <k> bulkThen(Resolvable(FRef(NAME:String))) => Column(NAME) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: pre-existing bulk_update() behavior wrapped non-expression values in Value(attr).
  // - from_frame_condition: the fix must not change literal assignment semantics.
  claim
    <k> bulkThen(Plain(V:String)) => Param(V) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_hint: checking resolve_expression accepts expression-like values generally.
  // - from_code: BaseExpression._parse_expressions() and update/query paths use the same protocol.
  claim
    <k> bulkThen(Resolvable(ExprNode(SQL:String))) => ExprNode(SQL) </k>
    [all-path]
endmodule
