module MINI-CONSTRAINT-VALIDATION-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX
  imports MAP-SYNTAX

  syntax Code ::= "NoCode" | "Code" "(" String ")"
  syntax Kind ::= "Check" | "UniqueExpr" | "UniqueCond" | "UniqueFieldsLegacy" | "Exclusion"
  syntax Outcome ::= "NoOutcome" | "Ok" | "ValidationError" "(" Code ")" | "LegacyUniqueError"
  syntax Cmd ::= "init" "(" Code ")"
               | "deconstruct"
               | "validate" "(" Kind "," Bool ")"
endmodule

module MINI-CONSTRAINT-VALIDATION
  imports MINI-CONSTRAINT-VALIDATION-SYNTAX
  imports BOOL
  imports STRING
  imports MAP

  configuration
    <k> $PGM:Cmd </k>
    <code> NoCode </code>
    <kwargs> .Map </kwargs>
    <out> NoOutcome </out>

  rule <k> init(C:Code) => .K </k>
       <code> _ => C </code>

  rule <k> deconstruct => .K </k>
       <code> Code(S) </code>
       <kwargs> KW => KW [ "violation_error_code" <- S ] </kwargs>

  rule <k> deconstruct => .K </k>
       <code> NoCode </code>

  rule <k> validate(Check, true) => .K </k>
       <code> C </code>
       <out> _ => ValidationError(C) </out>

  rule <k> validate(UniqueExpr, true) => .K </k>
       <code> C </code>
       <out> _ => ValidationError(C) </out>

  rule <k> validate(UniqueCond, true) => .K </k>
       <code> C </code>
       <out> _ => ValidationError(C) </out>

  rule <k> validate(Exclusion, true) => .K </k>
       <code> C </code>
       <out> _ => ValidationError(C) </out>

  rule <k> validate(UniqueFieldsLegacy, true) => .K </k>
       <out> _ => LegacyUniqueError </out>

  rule <k> validate(K:Kind, false) => .K </k>
       <out> _ => Ok </out>
endmodule
