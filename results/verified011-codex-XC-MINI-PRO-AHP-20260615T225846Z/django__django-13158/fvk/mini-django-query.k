module MINI-DJANGO-QUERY-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX

  syntax Combinator ::= "noComb"
                      | "unionComb"
                      | "intersectionComb"
                      | "differenceComb"

  syntax Queries ::= ".Queries"
                   | Query ";" Queries [right]

  syntax Query ::= "query" "(" Bool "," Combinator "," Queries ")"
                 | "setEmpty" "(" Query ")" [function]

  syntax ResultType ::= "multi" | "single"

  syntax SqlResult ::= "emptyResult"
                     | "unsupported"
                     | "sql" "(" Int ")"

  syntax ExecResult ::= "rows" "(" Int ")"
                      | "noResult"
                      | "unsupportedExec"

  syntax KItem ::= "asSql" "(" Query "," Bool ")"
                 | "executeSql" "(" Query "," Bool "," ResultType ")"
                 | "finishExecute" "(" ResultType ")"
                 | "combineSql" "(" Combinator "," Queries ")"
                 | "cleanEmpty" "(" Query ")"

  syntax KResult ::= Query | SqlResult | ExecResult
endmodule

module MINI-DJANGO-QUERY
  imports MINI-DJANGO-QUERY-SYNTAX
  imports BOOL
  imports INT

  configuration
    <k> $PGM:K </k>
    <cursors> 0 </cursors>

  // QuerySet.none() delegates to Query.set_empty(); only the empty marker is
  // relevant to the issue, so combined-query metadata is preserved.
  rule setEmpty(query(_, C:Combinator, QS:Queries)) => query(true, C, QS)

  // ModelMultipleChoiceField.clean(empty) returns self.queryset.none().
  rule <k> cleanEmpty(Q:Query) => setEmpty(Q) ... </k>

  // V2 behavior: an outer empty query reaches the no-results signal before
  // backend combinator support or combined operand SQL is inspected.
  rule <k> asSql(query(true, C:Combinator, QS:Queries), SUPPORTS:Bool) => emptyResult ... </k>

  // Frame behavior for non-empty ordinary and combined queries.
  rule <k> asSql(query(false, noComb, QS:Queries), SUPPORTS:Bool) => sql(1) ... </k>
  rule <k> asSql(query(false, C:Combinator, QS:Queries), false) => unsupported ... </k>
    requires C =/=K noComb
  rule <k> asSql(query(false, C:Combinator, QS:Queries), true) => combineSql(C, QS) ... </k>
    requires C =/=K noComb
  rule <k> combineSql(C:Combinator, QS:Queries) => sql(1) ... </k>

  // SQLCompiler.execute_sql(): EmptyResultSet is consumed before cursor
  // creation; normal SQL opens one cursor.
  rule <k> executeSql(Q:Query, SUPPORTS:Bool, multi) => asSql(Q, SUPPORTS) ~> finishExecute(multi) ... </k>
  rule <k> emptyResult ~> finishExecute(multi) => rows(0) ... </k>
  rule <k> sql(N:Int) ~> finishExecute(multi) => rows(N) ... </k>
       <cursors> C:Int => C +Int 1 </cursors>
  rule <k> unsupported ~> finishExecute(RT:ResultType) => unsupportedExec ... </k>
endmodule
