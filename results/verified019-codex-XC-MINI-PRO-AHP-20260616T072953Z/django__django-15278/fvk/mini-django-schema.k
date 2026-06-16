module MINI-DJANGO-SCHEMA-SYNTAX
  imports BOOL-SYNTAX

  // Abstract field shape for the SQLite add_field() branch decision.
  // field(NULL, HASDEFAULT, UNIQUE)
  syntax Field ::= "field" "(" Bool "," Bool "," Bool ")"
  syntax Decision ::= "Remake" | "BaseAdd"
  syntax Op ::= "addField" "(" Field ")"
  syntax KResult ::= Decision
endmodule

module MINI-DJANGO-SCHEMA
  imports MINI-DJANGO-SCHEMA-SYNTAX
  imports BOOL

  configuration <k> $PGM:Op </k>

  syntax Bool ::= shouldRemake(Field) [function]
  rule shouldRemake(field(NULL:Bool, HASDEFAULT:Bool, UNIQUE:Bool))
    => notBool NULL orBool HASDEFAULT orBool UNIQUE

  rule <k> addField(F:Field) => Remake ... </k>
    requires shouldRemake(F)

  rule <k> addField(F:Field) => BaseAdd ... </k>
    requires notBool shouldRemake(F)

  // Property-complete abstraction of BaseDatabaseSchemaEditor.column_sql():
  // the base ADD COLUMN path emits inline UNIQUE exactly when field.unique is
  // true. The SQLite proof must prevent BaseAdd for those fields.
  syntax Bool ::= baseAddSqlHasInlineUnique(Field) [function]
  rule baseAddSqlHasInlineUnique(field(NULL:Bool, HASDEFAULT:Bool, UNIQUE:Bool)) => UNIQUE
endmodule
