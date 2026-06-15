module MINI-DJANGO-JSON-LOOKUP-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Backend ::= "mysql" | "sqlite" | "oracle" | "postgresql" | "other"
  syntax JVal ::= jNull | jNum(Int) | jStr(String) | jBool(Bool) | jArray | jObject
  syntax ParamKind ::= literal(JVal) | expression
  syntax SqlFrag ::= ph
                   | mysqlJsonExtract(SqlFrag)
                   | sqliteJsonExtract(SqlFrag)
                   | oracleJsonValue(String)
                   | oracleJsonQuery(String)
                   | inherited(SqlFrag)
                   | compiledExpression
  syntax Adapted ::= adapted(SqlFrag, Int)
  syntax Split ::= split(Int, Int, Int)
  syntax KResult ::= Adapted | Split

  syntax Stmt ::= adapt(Backend, Bool, ParamKind)
                | oracleSplit(Int, Int, Int)
endmodule

module MINI-DJANGO-JSON-LOOKUP
  imports MINI-DJANGO-JSON-LOOKUP-SYNTAX
  imports INT
  imports BOOL
  imports STRING

  configuration <k> $PGM:Stmt </k>

  syntax String ::= quoteSafe(JVal) [function]
  rule quoteSafe(jNull) => "{\"value\": null}"
  rule quoteSafe(jNum(I)) => "{\"value\": <num>}"
  rule quoteSafe(jBool(true)) => "{\"value\": true}"
  rule quoteSafe(jBool(false)) => "{\"value\": false}"
  rule quoteSafe(jStr(S)) => "{quote-safe-string}"
  rule quoteSafe(jArray) => "{quote-safe-array}"
  rule quoteSafe(jObject) => "{quote-safe-object}"

  rule <k> adapt(mysql, false, literal(V)) => adapted(mysqlJsonExtract(ph), 1) </k>
  rule <k> adapt(sqlite, false, literal(jNull)) => adapted(ph, 1) </k>
  rule <k> adapt(sqlite, false, literal(V)) => adapted(sqliteJsonExtract(ph), 1) </k>
    requires V =/=K jNull
  rule <k> adapt(oracle, false, literal(jArray)) => adapted(oracleJsonQuery(quoteSafe(jArray)), 0) </k>
  rule <k> adapt(oracle, false, literal(jObject)) => adapted(oracleJsonQuery(quoteSafe(jObject)), 0) </k>
  rule <k> adapt(oracle, false, literal(V)) => adapted(oracleJsonValue(quoteSafe(V)), 0) </k>
    requires V =/=K jArray andBool V =/=K jObject
  rule <k> adapt(B, true, literal(V)) => adapted(inherited(ph), 1) </k>
  rule <k> adapt(B, Native, expression) => adapted(compiledExpression, 1) </k>

  rule <k> oracleSplit(N, Max, 0) => split(N, Max, (N +Int Max -Int 1) /Int Max) </k>
    requires N >Int Max andBool Max >Int 0
  rule <k> oracleSplit(N, Max, P) => split(N, Max, (P +Int Max -Int 1) /Int Max) </k>
    requires N >Int Max andBool Max >Int 0 andBool P >Int 0
endmodule
