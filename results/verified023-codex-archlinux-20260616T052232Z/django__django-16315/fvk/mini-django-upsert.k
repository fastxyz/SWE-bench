module MINI-DJANGO-UPSERT-SYNTAX
  imports STRING
  imports LIST
  imports MAP

  syntax Conflict ::= "none" | "ignore" | "update"
  syntax Field ::= field(String, String)

  syntax List ::= resolveFields(Map, List) [function]
  syntax List ::= fieldColumns(List) [function]
  syntax List ::= queryFields(Conflict, Map, List) [function]
  syntax List ::= compilerFields(Conflict, List) [function]
endmodule

module MINI-DJANGO-UPSERT
  imports MINI-DJANGO-UPSERT-SYNTAX

  configuration <k> $PGM:K </k>

  rule resolveFields(FM, .List) => .List
  rule resolveFields(FM, ListItem(N) REST)
    => ListItem(FM [ N ]) resolveFields(FM, REST)

  rule fieldColumns(.List) => .List
  rule fieldColumns(ListItem(field(N, C)) REST)
    => ListItem(C) fieldColumns(REST)

  rule queryFields(update, FM, NAMES) => resolveFields(FM, NAMES)
  rule queryFields(none, FM, VALUES) => VALUES
  rule queryFields(ignore, FM, VALUES) => VALUES

  rule compilerFields(update, FIELDS) => fieldColumns(FIELDS)
  rule compilerFields(none, VALUES) => VALUES
  rule compilerFields(ignore, VALUES) => VALUES
endmodule
