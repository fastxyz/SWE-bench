requires "mini-django-case.k"

module DJANGO-CASE-SPEC
  imports MINI-DJANGO-CASE

  // SPEC-PROVENANCE:
  // - from_prompt: "I expected behavior to annotate all rows with the value True since they all match."
  //   => a full predicate in a When condition must select the then branch.
  // - from_prompt: generated SQL "CASE WHEN THEN True ELSE False END" is the reported bug.
  //   => the rendered searched CASE must not contain an empty WHEN condition.
  // - from_code: WhereNode.as_sql() documents "Return '', [] if this node matches everything".
  //   => Full abstracts the empty-SQL/full-result sentinel.
  claim <k> caseOneAsSql(Full, "True", .Params, "False", .Params)
        => render("CASE WHEN 1=1 THEN True ELSE False END", .Params)
       </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: When.as_sql() formats "WHEN %(condition)s THEN %(result)s".
  // - from_code: the V1 fix rewrites only the empty/full condition sentinel.
  //   => ordinary non-empty predicates must retain their SQL and parameter order.
  claim <k> whenAsSql(Pred("id = %s", params("7")), "True", params("then"))
        => render("WHEN id = %s THEN True", params("7") +Params params("then"))
       </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: expressions_case test_annotate_with_empty_when expects
  //   When(pk__in=[]) to fall through to the default.
  // - from_code: Case.as_sql() catches EmptyResultSet from case compilation and
  //   continues, returning the default when no case parts remain.
  //   => impossible predicates are skipped, not converted to true.
  claim <k> caseOneAsSql(Empty, "selected", .Params, "not selected", .Params)
        => render("not selected", .Params)
       </k>
    [all-path]
endmodule
