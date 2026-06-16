module MINI-DJANGO-SQLITE-WINDOW-SYNTAX
  imports BOOL-SYNTAX

  syntax FieldKind ::= "decimal" | "float" | "other"
  syntax SourceName ::= "lag" | "lead" | "aggregate" | "firstValue"
  syntax Source ::= "source" "(" SourceName "," FieldKind ")"

  syntax Sql ::= "raw" "(" SourceName ")"
               | "castNumeric" "(" Sql ")"
               | "over" "(" Sql ")"
               | "sourceSql" "(" Source ")" [function]
               | "sqliteNumeric" "(" FieldKind "," Sql ")" [function]
               | "windowSqlite" "(" FieldKind "," Source ")" [function]

  syntax Source ::= "forceFloat" "(" Source ")" [function]
  syntax SourceName ::= "sourceName" "(" Source ")" [function]
  syntax FieldKind ::= "sourceKind" "(" Source ")" [function]

  syntax Query ::= "compileSourceSqlite" "(" Source ")"
                 | "compileWindowSqlite" "(" FieldKind "," Source ")"
                 | "compileStandaloneSqlite" "(" Source ")"

  syntax KResult ::= Sql
endmodule

module MINI-DJANGO-SQLITE-WINDOW
  imports MINI-DJANGO-SQLITE-WINDOW-SYNTAX

  configuration <k> $PGM:Query </k>

  rule sourceName(source(N:SourceName, K:FieldKind)) => N
  rule sourceKind(source(N:SourceName, K:FieldKind)) => K
  rule forceFloat(source(N:SourceName, K:FieldKind)) => source(N, float)

  rule sqliteNumeric(decimal, SQL:Sql) => castNumeric(SQL)
  rule sqliteNumeric(float, SQL:Sql) => SQL
  rule sqliteNumeric(other, SQL:Sql) => SQL

  rule sourceSql(S:Source) => sqliteNumeric(sourceKind(S), raw(sourceName(S)))

  // V1 behavior: Decimal-valued Window compiles the source as Float first,
  // then lets SQLiteNumericMixin cast the completed OVER expression.
  rule windowSqlite(decimal, S:Source) => sqliteNumeric(decimal, over(sourceSql(forceFloat(S))))
  rule windowSqlite(float, S:Source) => over(sourceSql(S))
  rule windowSqlite(other, S:Source) => over(sourceSql(S))

  rule <k> compileSourceSqlite(S:Source) => sourceSql(S) </k>
  rule <k> compileStandaloneSqlite(S:Source) => sourceSql(S) </k>
  rule <k> compileWindowSqlite(K:FieldKind, S:Source) => windowSqlite(K, S) </k>
endmodule
