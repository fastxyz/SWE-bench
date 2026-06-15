requires "mini-django-query.k"

module DJANGO-QUERY-NONE-SPEC
  imports MINI-DJANGO-QUERY

  // SPEC-PROVENANCE:
  // - E1/E2: QuerySet.none() on combined queries must return an empty queryset.
  // - E3: none() querysets never return objects and execute no database query.
  // - E5: QuerySet.none() produces the empty marker through Query.set_empty().
  claim
    <k> asSql(setEmpty(Q:Query), SUPPORTS:Bool) => emptyResult ... </k>
    <cursors> CURS:Int => CURS </cursors>
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E6: EmptyResultSet is the existing no-results path consumed by
  //   execute_sql(MULTI), before cursor creation.
  claim
    <k> executeSql(setEmpty(Q:Query), SUPPORTS:Bool, multi) => rows(0) ... </k>
    <cursors> CURS:Int => CURS </cursors>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4: ModelMultipleChoiceField's empty value is self.queryset.none().
  claim
    <k> cleanEmpty(Q:Query) => setEmpty(Q) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - I5/PO-06: non-empty combined queries retain their existing unsupported
  //   backend behavior.
  claim
    <k> asSql(query(false, C:Combinator, QS:Queries), false) => unsupported ... </k>
    requires C =/=K noComb
    [all-path]

  // SPEC-PROVENANCE:
  // - I5/PO-06: non-empty supported combined queries still delegate to combined
  //   SQL assembly.
  claim
    <k> asSql(query(false, C:Combinator, QS:Queries), true) => sql(1) ... </k>
    requires C =/=K noComb
    [all-path]
endmodule
