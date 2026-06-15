requires "mini-django-json-lookup.k"

module JSON-KEY-TRANSFORM-IN-SPEC
  imports MINI-DJANGO-JSON-LOOKUP
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - E1/E2/E3: MySQL key-transform IN must compare JSON RHS values, including single-element lists.
  // - E5: Existing exact lookup uses JSON_EXTRACT on MySQL RHS.
  claim <k> adapt(mysql, false, literal(V:JVal)) => adapted(mysqlJsonExtract(ph), 1) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2/E3: SQLite key-transform IN must compare JSON RHS values, including single-element lists.
  // - E5: Existing exact lookup uses JSON_EXTRACT for non-null SQLite RHS.
  claim <k> adapt(sqlite, false, literal(V:JVal)) => adapted(sqliteJsonExtract(ph), 1) </k>
    requires V =/=K jNull
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: Existing exact lookup preserves the null placeholder on SQLite.
  // - F3: Generic IN removes Python None before this path; this claim models a prepared JSON null value only.
  claim <k> adapt(sqlite, false, literal(jNull)) => adapted(ph, 1) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2/E4: Oracle strings/scalars in key-transform IN are in scope.
  // - PO5: quoteSafe abstracts SQL-single-quote doubling by _json_value_literal().
  claim <k> adapt(oracle, false, literal(V:JVal)) => adapted(oracleJsonValue(quoteSafe(V)), 0) </k>
    requires V =/=K jArray andBool V =/=K jObject
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E5: IN must mirror exact lookup's JSON_QUERY branch for arrays/objects.
  claim <k> adapt(oracle, false, literal(jArray)) => adapted(oracleJsonQuery(quoteSafe(jArray)), 0) </k>
    [all-path]

  claim <k> adapt(oracle, false, literal(jObject)) => adapted(oracleJsonQuery(quoteSafe(jObject)), 0) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - I3/PO7: Native JSON backends preserve inherited behavior.
  claim <k> adapt(postgresql, true, literal(V:JVal)) => adapted(inherited(ph), 1) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - PO7: Expression RHS values preserve inherited expression compilation.
  claim <k> adapt(B:Backend, Native:Bool, expression) => adapted(compiledExpression, 1) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - F1/PO6: Oracle inline RHS fragments have zero params, so split by RHS fragment count.
  claim <k> oracleSplit(N:Int, Max:Int, 0) => split(N, Max, (N +Int Max -Int 1) /Int Max) </k>
    requires N >Int Max andBool Max >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - PO6/PO7: If RHS params are present, generic param-count splitting remains valid.
  claim <k> oracleSplit(N:Int, Max:Int, P:Int) => split(N, Max, (P +Int Max -Int 1) /Int Max) </k>
    requires N >Int Max andBool Max >Int 0 andBool P >Int 0
    [all-path]
endmodule
