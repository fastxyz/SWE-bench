module MINI-MIGRATION-SERIALIZER-SYNTAX
  imports STRING-SYNTAX
  imports SET-SYNTAX

  syntax TypeVal ::= "ModelsModel"
                   | "NoneType"
                   | "BuiltinType" "(" String ")"
                   | "CustomType" "(" String "," String ")"

  syntax Ser ::= "ser" "(" String "," Set ")"
               | "serializeType" "(" TypeVal ")"               [function]
               | "serializeTuple2" "(" TypeVal "," TypeVal ")" [function]
               | "mergeTuple2" "(" Ser "," Ser ")"             [function]

  syntax String ::= "renderDjangoDbImport" "(" Set ")"          [function]

  syntax Exp ::= Ser | String

  syntax KResult ::= String | Set | Ser
endmodule

module MINI-MIGRATION-SERIALIZER
  imports MINI-MIGRATION-SERIALIZER-SYNTAX
  imports STRING
  imports SET
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // TypeSerializer.serialize() special cases and preserved branches.
  rule serializeType(ModelsModel)
    => ser("models.Model", SetItem("from django.db import models"))
    [function]

  rule serializeType(NoneType)
    => ser("type(None)", .Set)
    [function]

  rule serializeType(BuiltinType(N:String))
    => ser(N, .Set)
    [function]

  rule serializeType(CustomType(M:String, Q:String))
    => ser(M +String "." +String Q, SetItem("import " +String M))
    [function]

  // BaseSequenceSerializer.serialize() for the reported two-base shape:
  // serialize each item, concatenate the tuple text, and union item imports.
  rule serializeTuple2(T1:TypeVal, T2:TypeVal)
    => mergeTuple2(serializeType(T1), serializeType(T2))
    [function]

  rule mergeTuple2(ser(S1:String, I1:Set), ser(S2:String, I2:Set))
    => ser("(" +String S1 +String ", " +String S2 +String ")", I1 I2)
    [function]

  // MigrationWriter.as_string() import merge behavior.
  rule renderDjangoDbImport(SetItem("from django.db import models") REST:Set)
    => "from django.db import migrations, models"
    [function]

  rule renderDjangoDbImport(I:Set)
    => "from django.db import migrations"
    requires notBool ("from django.db import models" in I)
    [function]
endmodule
