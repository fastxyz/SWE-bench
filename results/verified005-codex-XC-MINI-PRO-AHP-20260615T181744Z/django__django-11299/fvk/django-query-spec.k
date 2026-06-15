// Constructed for FVK audit of django__django-11299.
// Status: constructed, not machine-checked.

requires "mini-django-query.k"

module MINI-DJANGO-QUERY-SPEC-SYNTAX
  imports MINI-DJANGO-QUERY-SYNTAX
endmodule

module VERIFICATION
  imports MINI-DJANGO-QUERY
  imports MINI-DJANGO-QUERY-SPEC-SYNTAX

  syntax ModeTree ::= simpleShape(QTree) [function]
                    | colShape(QTree) [function]

  rule simpleShape(leaf) => simpleLeaf
  rule simpleShape(node(L:QTree, R:QTree)) => nodeM(simpleShape(L), simpleShape(R))

  rule colShape(leaf) => colLeaf
  rule colShape(node(L:QTree, R:QTree)) => nodeM(colShape(L), colShape(R))
endmodule

module MINI-DJANGO-QUERY-SPEC
  imports VERIFICATION

  // SPEC-PROVENANCE:
  // - from_prompt: "The proper CREATE TABLE query should look like ... CHECK
  //   (((\"field_1\" IS NOT NULL AND \"flag\" = 1) OR \"flag\" = 0))"
  //   => every leaf under a schema predicate compiled with simple_col=True
  //      must render in SimpleCol mode, regardless of Q nesting.
  // - from_code: Query.build_where() calls _add_q(..., simple_col=True);
  //   build_filter() passes simple_col to _get_col().
  claim
    <k> compile(Q:QTree, true) => simpleShape(Q) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_compatibility: ordinary Query.add_q() calls _add_q() without
  //   simple_col=True and must keep table-qualified Col behavior.
  // - from_code: simple_col defaults to False on _add_q().
  claim
    <k> compile(Q:QTree, false) => colShape(Q) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: reported shape is an OR whose left side is an AND over
  //   field_1 and flag and whose right side is flag.
  claim
    <k> compile(node(node(leaf, leaf), leaf), true)
      => nodeM(nodeM(simpleLeaf, simpleLeaf), simpleLeaf) ... </k>
    [all-path]
endmodule
