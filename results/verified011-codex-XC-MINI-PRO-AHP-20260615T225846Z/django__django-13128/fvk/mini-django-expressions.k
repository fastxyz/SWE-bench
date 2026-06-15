module MINI-DJANGO-EXPRESSIONS-SYNTAX
  imports BOOL-SYNTAX

  syntax Connector ::= "ADD" | "SUB" | "MUL" | "DIV"

  syntax FieldType ::= "DateField"
                     | "DateTimeField"
                     | "TimeField"
                     | "DurationField"
                     | "IntegerField"
                     | "OtherField"
                     | "UnknownField"
                     | "FieldError"

  syntax SqlKind ::= "TemporalSubtractionSQL"
                   | "GenericCombinedSQL"

  syntax FieldType ::= resolveOutput(Connector, FieldType, FieldType) [function]
                     | genericOutput(FieldType, FieldType) [function]
                     | sqlOutput(SqlKind) [function]

  syntax SqlKind ::= sqlKind(Connector, FieldType, FieldType) [function]

  syntax Bool ::= sameTemporalSub(Connector, FieldType, FieldType) [function]
endmodule

module MINI-DJANGO-EXPRESSIONS
  imports MINI-DJANGO-EXPRESSIONS-SYNTAX
  imports BOOL
  imports K-EQUAL

  configuration <k> $PGM:K </k>

  rule sameTemporalSub(SUB, DateField, DateField) => true
  rule sameTemporalSub(SUB, DateTimeField, DateTimeField) => true
  rule sameTemporalSub(SUB, TimeField, TimeField) => true
  rule sameTemporalSub(_, _, _) => false [owise]

  rule resolveOutput(C:Connector, L:FieldType, R:FieldType) => DurationField
    requires sameTemporalSub(C, L, R)
  rule resolveOutput(C:Connector, L:FieldType, R:FieldType) => genericOutput(L, R)
    requires notBool sameTemporalSub(C, L, R)

  // Mirrors BaseExpression._resolve_output_field() for the cases needed here:
  // matching known source types resolve to that type; mixed known types fail;
  // UnknownField represents a source whose output field is ignored.
  rule genericOutput(T:FieldType, T:FieldType) => T
    requires T =/=K UnknownField
  rule genericOutput(UnknownField, T:FieldType) => T
    requires T =/=K UnknownField
  rule genericOutput(T:FieldType, UnknownField) => T
    requires T =/=K UnknownField
  rule genericOutput(UnknownField, UnknownField) => FieldError
  rule genericOutput(L:FieldType, R:FieldType) => FieldError
    requires L =/=K R andBool L =/=K UnknownField andBool R =/=K UnknownField

  rule sqlKind(C:Connector, L:FieldType, R:FieldType) => TemporalSubtractionSQL
    requires sameTemporalSub(C, L, R)
  rule sqlKind(_, _, _) => GenericCombinedSQL [owise]

  rule sqlOutput(TemporalSubtractionSQL) => DurationField
  rule sqlOutput(GenericCombinedSQL) => OtherField
endmodule
