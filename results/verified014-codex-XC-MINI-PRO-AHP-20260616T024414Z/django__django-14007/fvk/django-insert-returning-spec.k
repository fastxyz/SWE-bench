requires "mini-django-insert.k"

module DJANGO-INSERT-RETURNING-SPEC
  imports MINI-DJANGO-INSERT

  // SPEC-PROVENANCE:
  // - E-005 compatibility: no returning_fields returns [].
  claim <k> executeSql(noReturningFields) => list(.Rows) </k> [all-path]

  // SPEC-PROVENANCE:
  // - E-001/E-002/E-004: bulk insert returned rows must be converted.
  claim
    <k> executeSql(bulkRows(RS:Rows, FS:Fields)) => list(convertRows(RS, FS)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-001/E-002/E-003: single insert returned columns must be converted.
  claim
    <k> executeSql(singleRow(R:Row, FS:Fields)) => list(convertRows(R ; .Rows, FS)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-007: last_insert_id returns a primary key only.
  claim
    <k> executeSql(lastId(ID:Int)) => list(convertRows((ID , .Row) ; .Rows, pk , .Fields)) </k>
    [all-path]
endmodule
