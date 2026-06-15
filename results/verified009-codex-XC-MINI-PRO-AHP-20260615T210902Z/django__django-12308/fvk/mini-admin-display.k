module MINI-ADMIN-DISPLAY-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Value ::= none
                 | jsonObject(String, String)
                 | jsonString(String)
                 | invalidJson(String)
                 | pyValue(String)

  syntax Field ::= jsonField(String)
                 | postgresJsonField(String)
                 | normalField

  syntax Display ::= emptyDisplay(String)
                   | preparedJson(Value, String)
                   | rawJson(String)
                   | pyRepr(Value)

  syntax Expr ::= displayForField(Value, Field, Display)
                | prepareJsonValue(Value, String)

  syntax KResult ::= Display
endmodule

module MINI-ADMIN-DISPLAY
  imports MINI-ADMIN-DISPLAY-SYNTAX
  imports BOOL

  configuration <k> $PGM:Expr </k>

  syntax Bool ::= isNone(Value) [function]
  rule isNone(none) => true
  rule isNone(V:Value) => false [owise]

  syntax Bool ::= isInvalidJson(Value) [function]
  rule isInvalidJson(invalidJson(S:String)) => true
  rule isInvalidJson(V:Value) => false [owise]

  // Admin's existing general null branch precedes JSONField formatting.
  rule <k> displayForField(none, FIELD:Field, EMPTY:Display) => EMPTY </k>

  // The deprecated postgres JSONField is a subclass of the built-in model field.
  rule <k> displayForField(V:Value, postgresJsonField(ENC:String), EMPTY:Display)
        => displayForField(V, jsonField(ENC), EMPTY)
       </k>
    requires notBool isNone(V)

  // V1 JSONField branch: field.formfield().prepare_value(value).
  rule <k> displayForField(V:Value, jsonField(ENC:String), EMPTY:Display)
        => prepareJsonValue(V, ENC)
       </k>
    requires notBool isNone(V)

  // forms.JSONField.prepare_value() preserves InvalidJSONInput.
  rule <k> prepareJsonValue(invalidJson(S:String), ENC:String) => rawJson(S) </k>

  // Otherwise prepare_value serializes with the configured encoder.
  rule <k> prepareJsonValue(V:Value, ENC:String) => preparedJson(V, ENC) </k>
    requires notBool isInvalidJson(V)

  // Non-JSON fields retain the generic repr-like fallback in this model.
  rule <k> displayForField(V:Value, normalField, EMPTY:Display) => pyRepr(V) </k>
    requires notBool isNone(V)
endmodule
