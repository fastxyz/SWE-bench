requires "mini-django-query.k"

module QUERY-FILTERABLE-SPEC
  imports MINI-DJANGO-QUERY

  // SPEC-PROVENANCE:
  // - E-01/E-02/E-03: ordinary RHS values with filterable=False are valid
  //   lookup data, not non-filterable expressions.
  claim
    <k> checkFilterable(obj(false, FILTERABLE:Bool, HAS_SOURCES:Bool, SOURCES:List))
      => ok
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-04: real expressions with filterable=False are disallowed in WHERE.
  claim
    <k> checkFilterable(obj(true, false, HAS_SOURCES:Bool, SOURCES:List))
      => notSupported
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-04: a filterable expression without source expressions is accepted.
  claim
    <k> checkFilterable(obj(true, true, false, SOURCES:List))
      => ok
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-04/E-05: source-expression traversal is expression-protocol behavior.
  claim
    <k> checkFilterable(obj(true, true, true, .List))
      => ok
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-04/E-05: non-empty source lists validate the head, then the tail.
  claim
    <k> checkFilterable(obj(true, true, true, ListItem(SRC:Obj) REST:List))
      => checkFilterable(SRC) ~> checkSources(REST)
    </k>
    [all-path]
endmodule
