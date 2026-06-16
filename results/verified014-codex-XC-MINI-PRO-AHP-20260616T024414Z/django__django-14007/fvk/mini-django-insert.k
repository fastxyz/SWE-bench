module MINI-DJANGO-INSERT-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX

  syntax Field ::= "pk" | "field" "(" Int ")"
  syntax Fields ::= ".Fields" | Field "," Fields
  syntax Row ::= ".Row" | Int "," Row
  syntax Rows ::= ".Rows" | Row ";" Rows
                | "convertRows" "(" Rows "," Fields ")"
  syntax Branch ::= "noReturningFields"
                  | "bulkRows" "(" Rows "," Fields ")"
                  | "singleRow" "(" Row "," Fields ")"
                  | "lastId" "(" Int ")"
  syntax Result ::= "executeSql" "(" Branch ")"
                  | "list" "(" Rows ")"
endmodule

module MINI-DJANGO-INSERT
  imports MINI-DJANGO-INSERT-SYNTAX

  configuration <k> $PGM:Result </k>

  // Abstract semantics for the post-fetch part of SQLInsertCompiler.execute_sql().
  // convertRows represents backend converters followed by field converters for
  // each row position.
  rule <k> executeSql(noReturningFields) => list(.Rows) </k>
  rule <k> executeSql(bulkRows(RS, FS)) => list(convertRows(RS, FS)) </k>
  rule <k> executeSql(singleRow(R, FS)) => list(convertRows(R ; .Rows, FS)) </k>
  rule <k> executeSql(lastId(ID)) => list(convertRows((ID , .Row) ; .Rows, pk , .Fields)) </k>
endmodule
