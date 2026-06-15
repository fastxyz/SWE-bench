requires "mini-query-clone.k"

module QUERY-CLONE-SPEC
  imports MINI-QUERY-CLONE
  imports K-EQUAL
  imports MAP

  // SPEC-PROVENANCE:
  // - from_prompt: "Union queryset with ordering breaks on ordering with
  //   derived querysets" => derived values_list must not corrupt the original
  //   ordered union.
  // - from_prompt_traceback: "ORDER BY position 4 is not in select list" =>
  //   the original components must retain width >= 4.
  // - from_hint: ".query attribute change without performing a prior copy()"
  //   => component queries must be cloned before derived select-list changes.
  // - from_code: QuerySet derivation reaches Query.clone() through
  //   Query.chain(), so Query.clone() is the proof target.
  claim [ORDERED-UNION-DERIVED-VALUES-FRAME]:
    <k>
      deriveValuesPk(orig, derived, d1, d2) ;
      assertOrderable(orig)
      => .K
    </k>
    <queries>
      orig |-> query(4, 4, kids(c1, c2))
      c1   |-> query(4, 0, noKids)
      c2   |-> query(4, 0, noKids)
      .Map
      =>
      orig    |-> query(4, 4, kids(c1, c2))
      c1      |-> query(4, 0, noKids)
      c2      |-> query(4, 0, noKids)
      derived |-> query(1, 0, kids(d1, d2))
      d1      |-> query(1, 0, noKids)
      d2      |-> query(1, 0, noKids)
      .Map
    </queries>
    <status> ok => ok </status>
    [all-path]
endmodule
