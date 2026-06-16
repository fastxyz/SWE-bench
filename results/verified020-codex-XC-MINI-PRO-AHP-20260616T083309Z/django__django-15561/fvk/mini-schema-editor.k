module MINI-SCHEMA-EDITOR-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Backend ::= "base" | "sqlite"
  syntax Field ::= field(String, String, String, String, String)
  syntax Bool ::= shouldAlter(Backend, Field, Field) [function]
                | sameDbRelevant(Field, Field) [function]
                | sameIncludingChoices(Field, Field) [function]
endmodule

module MINI-SCHEMA-EDITOR
  imports MINI-SCHEMA-EDITOR-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:Bool </k>

  // Field shape:
  // field(quotedColumn, path, argsFingerprint, dbRelevantKwargs, choices)
  //
  // dbRelevantKwargs is the deconstruction kwargs fingerprint after removing
  // the existing base ignored attrs: blank, db_column, editable,
  // error_messages, help_text, limit_choices_to, on_delete, related_name,
  // related_query_name, validators, and verbose_name.

  rule sameDbRelevant(field(C, P, A, K, CH1), field(C, P, A, K, CH2)) => true
  rule sameDbRelevant(F1:Field, F2:Field) => false [owise]

  rule sameIncludingChoices(field(C, P, A, K, CH), field(C, P, A, K, CH)) => true
  rule sameIncludingChoices(F1:Field, F2:Field) => false [owise]

  rule shouldAlter(base, OLD, NEW) => notBool sameIncludingChoices(OLD, NEW)
  rule shouldAlter(sqlite, OLD, NEW) => notBool sameDbRelevant(OLD, NEW)
endmodule
