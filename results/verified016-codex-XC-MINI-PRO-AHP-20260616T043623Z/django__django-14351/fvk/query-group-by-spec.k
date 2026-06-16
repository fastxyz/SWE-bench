requires "mini-orm-query.k"

module MINI-ORM-QUERY-SPEC
  imports MINI-ORM-QUERY

  // SPEC-PROVENANCE:
  // - from_prompt: "agent__property_groups__in gets all fields ... subquery must return only one column"
  //   => a non-correlated RHS queryset must not contribute the raw Query itself to GROUP BY.
  // - from_code: Query.get_external_cols() returns only columns from aliases external to the subquery.
  claim <k> getGroupByCols(none, .Exprs, false)
        => .Exprs
       </k>
       [all-path]

  // SPEC-PROVENANCE:
  // - from_code: Subquery.get_group_by_cols() returns external_cols when none are possibly multivalued.
  // - from_default_domain: a correlated scalar subquery must expose its outer-column dependencies.
  claim <k> getGroupByCols(none, extCol(1, false) ; .Exprs, false)
        => extCol(1, false) ; .Exprs
       </k>
       [all-path]

  // SPEC-PROVENANCE:
  // - from_code: Subquery.get_group_by_cols() falls back to grouping by itself when any external
  //   column is possibly multivalued.
  // - from_default_domain: preserve Django's existing conservative multivalued-correlated fallback.
  claim <k> getGroupByCols(none, extCol(1, true) ; .Exprs, true)
        => selfQuery ; .Exprs
       </k>
       [all-path]

  // SPEC-PROVENANCE:
  // - from_code: Subquery.get_group_by_cols(alias=alias) returns Ref(alias, self).
  // - from_default_domain: explicit group-by aliases should remain usable by reference.
  claim <k> getGroupByCols(alias(A:Int), CS:Exprs, HAS_MULTI:Bool)
        => ref(alias(A)) ; .Exprs
       </k>
       [all-path]
endmodule
