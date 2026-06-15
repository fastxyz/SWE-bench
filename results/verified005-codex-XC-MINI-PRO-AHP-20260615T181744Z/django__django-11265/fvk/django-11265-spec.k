requires "mini-django-query.k"

module DJANGO-11265-SPEC
  imports MINI-DJANGO-QUERY

  // SPEC-PROVENANCE:
  // - E-001/E-002/E-003: split_exclude must resolve a FilteredRelation alias.
  // - from_code: V1 copies _filtered_relations before query.add_filter().
  claim <k> splitExclude => .K </k>
        <st> state(true, false, true, FJ:Bool, C:Bool, UTA:Bool, W:Bool, T:Bool)
          => state(true, true, false, FJ, C, UTA, W, T) </st>
    [label(CLAIM-SPLIT-EXCLUDE-COPIES-FILTERED-RELATIONS)]

  // SPEC-PROVENANCE:
  // - E-004/E-005/E-006: copy-only is insufficient; the filtered condition
  //   must remain in the anti-subquery.
  // - from_code: V1 adds build_filtered_relation_q(...) to WHERE before trim
  //   when the condition does not use a trimmed alias.
  claim <k> trimStart => .K </k>
        <st> state(OFR:Bool, IFR:Bool, E:Bool, true, true, false, false, false)
          => state(OFR, IFR, E, true, true, false, true, true) </st>
    [label(CLAIM-TRIM-MOVES-FILTERED-CONDITION)]

  // SPEC-PROVENANCE:
  // - I-005: do not move a predicate into a query fragment where a referenced
  //   alias has been trimmed away.
  // - from_code: V1 sets trim_first_join = False in this case.
  claim <k> trimStart => .K </k>
        <st> state(OFR:Bool, IFR:Bool, E:Bool, true, true, true, false, false)
          => state(OFR, IFR, E, true, true, true, false, false) </st>
    [label(CLAIM-TRIM-KEEPS-PARENT-ALIAS-CONDITION)]

  // SPEC-PROVENANCE:
  // - I-006/I-007: preserve unfiltered split_exclude and trim_start behavior.
  claim <k> trimStart => .K </k>
        <st> state(OFR:Bool, IFR:Bool, E:Bool, false, C:Bool, UTA:Bool, W:Bool, false)
          => state(OFR, IFR, E, false, C, UTA, W, true) </st>
    [label(CLAIM-UNFILTERED-FRAME)]
endmodule

