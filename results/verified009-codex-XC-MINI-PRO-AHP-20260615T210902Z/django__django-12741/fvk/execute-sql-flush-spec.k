requires "mini-django-flush.k"

module MINI-DJANGO-FLUSH-SPEC-SYNTAX
  imports MINI-DJANGO-FLUSH-SYNTAX
endmodule

module VERIFICATION
  imports MINI-DJANGO-FLUSH
endmodule

module EXECUTE-SQL-FLUSH-SPEC
  imports VERIFICATION

  // SPEC-PROVENANCE:
  // - E7: Preserve the existing loop over sql_list.
  // - I3: Every SQL statement is executed once, in order.
  claim [EXEC-ALL]:
    <k> execAll(SQLS:SqlList) => .K ... </k>
    <executed> DONE:SqlList => concatSql(DONE, SQLS) </executed>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2: The explicit using argument is removed.
  // - E3: The alias is inferred from the bound operations instance.
  // - E7: Preserve transaction wrapper and ordered SQL execution.
  claim [EXECUTE-SQL-FLUSH]:
    <k> execFlush(SQLS:SqlList) => .K ... </k>
    <opsAlias> A:Alias </opsAlias>
    <canRollbackDDL> CAN:Bool </canRollbackDDL>
    <txnAlias> _ => A </txnAlias>
    <executed> .SqlList => SQLS </executed>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4/E8: The flush command resolves the connection and calls the simplified operation.
  claim [FLUSH-COMMAND-CALL]:
    <k> flushCommand(A:Alias, SQLS:SqlList) => .K ... </k>
    <opsAlias> _ => A </opsAlias>
    <txnAlias> _ => A </txnAlias>
    <executed> .SqlList => SQLS </executed>
    [all-path]
endmodule
