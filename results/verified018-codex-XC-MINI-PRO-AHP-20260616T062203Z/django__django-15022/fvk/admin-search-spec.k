requires "mini-admin-search.k"

module MINI-ADMIN-SEARCH-SPEC
  imports MINI-ADMIN-SEARCH
  imports LIST
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_docs: "each word must be in at least one of search_fields" =>
  //   qand(clausesFor(TS, LS)), where every term contributes qor(atomsFor(...)).
  // - from_issue: "each word ... leads to additional JOIN ... because of
  //   qs = qs.filter(...) pattern" => filter application count is one, not
  //   length(TS), for nonempty TS.
  // - from_code: V2 uses queryset.filter(*term_queries) after the loop.
  claim
    <k> adminSearch(LS:List, TS:List, DUP:Bool)
      => result(qand(clausesFor(TS, LS)), 1, DUP)
    </k>
    requires notBool isEmpty(TS)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: with no parsed terms, V2 does not call queryset.filter().
  // - from_docs: an empty token stream imposes no word-match obligation.
  claim
    <k> adminSearch(LS:List, .List, DUP:Bool)
      => result(qtrue, 0, DUP)
    </k>
    [all-path]
endmodule
