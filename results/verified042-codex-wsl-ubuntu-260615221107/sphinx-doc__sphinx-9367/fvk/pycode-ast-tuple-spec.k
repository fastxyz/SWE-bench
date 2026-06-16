requires "mini-pycode-unparse.k"

module PYCODE-AST-TUPLE-SPEC
  imports MINI-PYCODE-UNPARSE

  // SPEC-PROVENANCE:
  // - from_prompt: "`(1,)` is rendered as `(1)`, but should keep the trailing comma."
  //   => a one-element Tuple expression renders with a trailing comma.
  // - from_public_test_hint: "(`(1,)`, `(1,)`)"
  //   => direct one-element tuple output is exactly the tuple syntax.
  claim <k> render(Tuple(E:Expr)) => "(" +String render(E) +String ",)" </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "special case of a 1-element tuple"
  //   => the comma is part of tuple cardinality, not only literal parentheses.
  // - from_code: visit_Subscript has a separate simple-tuple slice formatter.
  //   => the sibling contributor must preserve the same cardinality marker.
  claim <k> render(Subscript(V:Expr, Tuple(E:Expr)))
       => render(V) +String "[" +String render(E) +String ",]" </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: existing pycode AST tests cover empty and multi-element tuples.
  //   => V2 must preserve those non-buggy forms.
  claim <k> render(Tuple(.Exprs)) => "()" </k>
    [all-path]

  claim <k> render(Tuple(E:Expr , ES:Exprs))
       => "(" +String render(E) +String ", " +String joinTuple(ES) +String ")" </k>
    [all-path]
endmodule
