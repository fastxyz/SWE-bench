requires "mini-django-query.k"

module GET-AGGREGATION-SPEC
  imports MINI-DJANGO-QUERY
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: aggregating Sum("cumul_DJR") over a Window annotation must
  //   avoid aggregate-over-window SQL.
  // - from_docs: aggregates may reference aliases from annotate().
  // - from_code: refs_window is computed from aggregate.get_refs() and
  //   annotation.contains_over_clause.
  // CLAIM: window-ref-forces-wrapper
  claim
    <k> aggregateDecision(GB:Bool, SL:Bool, HEA:Bool, RS:Bool, true, Q:Bool, DS:Bool, CB:Bool)
      => Wrapped </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the reported minimal failure has no necessary trigger other
  //   than the selected window annotation reference.
  // - from_code: the wrapper path preserves Ref aliases in the outer aggregate.
  // CLAIM: window-ref-produces-safe-sql-shape
  claim
    <k> aggregateSqlShape(false, false, false, false, true, false, false, false)
      => SafeOuterAlias </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/docs: existing wrapping reasons must not regress.
  // CLAIM: existing-trigger-still-wraps
  claim
    <k> aggregateDecision(GB:Bool, SL:Bool, HEA:Bool, RS:Bool, RW:Bool, Q:Bool, DS:Bool, CB:Bool)
      => Wrapped </k>
    requires ((((((GB orBool SL) orBool HEA) orBool RS) orBool Q) orBool DS) orBool CB)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/docs: when no wrapping reason exists, the direct path remains
  //   available.
  // CLAIM: no-trigger-remains-direct
  claim
    <k> aggregateDecision(false, false, false, false, false, false, false, false)
      => Direct </k>
    [all-path]
endmodule
