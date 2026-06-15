requires "mini-django-queryset.k"

module LIMIT-CHOICES-TO-SPEC
  imports MINI-DJANGO-QUERYSET

  // Filtering a row list by a boolean predicate cannot introduce a new row or
  // duplicate an existing row. This is the cardinality lemma corresponding to
  // PO-2 in PROOF_OBLIGATIONS.md.
  rule uniquePks(existsFilter(RS:Rows, L:Limit)) => true
    requires uniquePks(RS)
    [simplification]

  // SPEC-PROVENANCE:
  // - from_prompt: "limit_choices_to ... involving a join ... duplicate options"
  //   => the limit filter must not expand one outer row into many choices.
  // - from_prompt: ".get() ... MultipleObjectsReturned"
  //   => validation over the same queryset must not see limit-induced duplicates.
  // - from_prompt: "distinct queries ... cause errors with some custom model fields"
  //   => the repair must avoid row-wide DISTINCT.
  // - from_code: V1 uses Exists(base_manager.filter(L & pk=OuterRef(pk))).
  claim
    <k> applyLimit(qs(RS:Rows), L:Limit) => qs(existsFilter(RS, L)) </k>
    requires uniquePks(RS)
    ensures uniquePks(existsFilter(RS, L))
    [all-path]
endmodule
