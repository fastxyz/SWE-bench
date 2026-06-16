module MINI-EXISTS-SYNTAX
  imports BOOL-SYNTAX

  syntax Sql ::= "TRUEPRED"
               | "EXISTSPRED"
               | "NOTEXISTSPRED"
               | "NAMEPRED"
               | "ANDPRED" "(" Sql "," Sql ")"

  syntax Result ::= "ok" "(" Sql ")"
                  | "emptyResult"

  syntax WhereResult ::= "whereSql" "(" Sql ")"
                       | "whereEmpty"

  syntax Prog ::= "existsAsSql" "(" Bool "," Bool ")"
                | "andWhere2" "(" Result "," Result ")"

  syntax KResult ::= Result | WhereResult
endmodule

module MINI-EXISTS
  imports MINI-EXISTS-SYNTAX
  imports BOOL

  configuration <k> $PGM:Prog </k>

  // existsAsSql(NEGATED, SUBQUERY_EMPTY)
  rule <k> existsAsSql(true, true) => ok(TRUEPRED) </k>
  rule <k> existsAsSql(false, true) => emptyResult </k>
  rule <k> existsAsSql(false, false) => ok(EXISTSPRED) </k>
  rule <k> existsAsSql(true, false) => ok(NOTEXISTSPRED) </k>

  // Minimal AND behavior needed for the reported WHERE-collapse symptom.
  rule <k> andWhere2(emptyResult, R:Result) => whereEmpty </k>
  rule <k> andWhere2(R:Result, emptyResult) => whereEmpty </k>
  rule <k> andWhere2(ok(S1:Sql), ok(S2:Sql)) => whereSql(ANDPRED(S1, S2)) </k>
endmodule
