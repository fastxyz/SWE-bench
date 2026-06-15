module MINI-DJANGO-FLUSH-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Alias ::= String
  syntax Sql ::= String
  syntax SqlList ::= ".SqlList"
                   | Sql ";" SqlList [right]

  syntax Unit ::= ".Unit"
  syntax KResult ::= Unit

  syntax Stmt ::= execFlush(SqlList)
                | execAll(SqlList)
                | flushCommand(Alias, SqlList)
                | beginAtomic(Alias, Bool)
                | endAtomic
                | execute(Sql)

  syntax SqlList ::= appendSql(SqlList, Sql) [function]
                   | concatSql(SqlList, SqlList) [function]
endmodule

module MINI-DJANGO-FLUSH
  imports MINI-DJANGO-FLUSH-SYNTAX

  configuration
    <k> $PGM:Stmt </k>
    <opsAlias> "" </opsAlias>
    <canRollbackDDL> true </canRollbackDDL>
    <txnAlias> "" </txnAlias>
    <executed> .SqlList </executed>

  rule appendSql(.SqlList, S:Sql) => S ; .SqlList
  rule appendSql(H:Sql ; T:SqlList, S:Sql) => H ; appendSql(T, S)

  rule concatSql(.SqlList, L:SqlList) => L
  rule concatSql(H:Sql ; T:SqlList, L:SqlList) => H ; concatSql(T, L)

  rule <k> .Unit => .K ... </k>

  rule <k> flushCommand(A:Alias, SQLS:SqlList) => execFlush(SQLS) ... </k>
       <opsAlias> _ => A </opsAlias>

  rule <k> execFlush(SQLS:SqlList) => beginAtomic(A, CAN) ~> execAll(SQLS) ~> endAtomic ... </k>
       <opsAlias> A </opsAlias>
       <canRollbackDDL> CAN </canRollbackDDL>

  rule <k> beginAtomic(A:Alias, _CAN:Bool) => .Unit ... </k>
       <txnAlias> _ => A </txnAlias>

  rule <k> endAtomic => .Unit ... </k>

  rule <k> execAll(.SqlList) => .Unit ... </k>
  rule <k> execAll(SQL:Sql ; REST:SqlList) => execute(SQL) ~> execAll(REST) ... </k>

  rule <k> execute(SQL:Sql) => .Unit ... </k>
       <executed> DONE => appendSql(DONE, SQL) </executed>
endmodule
