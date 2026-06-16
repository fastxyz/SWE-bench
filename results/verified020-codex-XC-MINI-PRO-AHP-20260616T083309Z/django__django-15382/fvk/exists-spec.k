requires "mini-exists.k"

module MINI-EXISTS-SPEC
  imports MINI-EXISTS

  // SPEC-PROVENANCE:
  // - E-001: negated Exists over an empty queryset must not remove the whole WHERE.
  // - E-003: catch EmptyResultSet in Exists.as_sql() and return an always-true predicate.
  claim <k> existsAsSql(true, true) => ok(TRUEPRED) </k> [all-path]

  // SPEC-PROVENANCE:
  // - Intent 2: positive Exists over an empty queryset remains always false.
  claim <k> existsAsSql(false, true) => emptyResult </k> [all-path]

  // SPEC-PROVENANCE:
  // - Intent 3: non-empty positive Exists compilation is preserved.
  claim <k> existsAsSql(false, false) => ok(EXISTSPRED) </k> [all-path]

  // SPEC-PROVENANCE:
  // - Intent 3: non-empty negated Exists compilation remains NOT EXISTS(...).
  claim <k> existsAsSql(true, false) => ok(NOTEXISTSPRED) </k> [all-path]

  // SPEC-PROVENANCE:
  // - E-001 and E-006: the true predicate produced for ~Exists(empty)
  //   keeps the remaining AND filter in SQL form.
  claim <k> andWhere2(ok(TRUEPRED), ok(NAMEPRED)) => whereSql(ANDPRED(TRUEPRED, NAMEPRED)) </k> [all-path]

  // SPEC-PROVENANCE:
  // - Intent 2 and E-006: a positive empty Exists child still collapses an AND.
  claim <k> andWhere2(emptyResult, ok(NAMEPRED)) => whereEmpty </k> [all-path]
endmodule
