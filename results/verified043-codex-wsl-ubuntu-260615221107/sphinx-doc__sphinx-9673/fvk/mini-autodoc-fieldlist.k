module MINI-AUTODOC-FIELDLIST-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Field ::= "paramField" "(" String ")"
                 | "paramTypedField" "(" String ")"
                 | "typeField" "(" String ")"
                 | "returnField"
                 | "returnsField"
                 | "rtypeField"
                 | "otherField" "(" String ")"

  syntax Fields ::= ".Fields"
                  | Field ";" Fields [right]

  syntax Result ::= "addRtype" "(" String ")"
                  | "noRtype"

  syntax Command ::= "augmentReturn" "(" Fields "," Bool "," String ")"

  syntax KResult ::= Result
endmodule

module MINI-AUTODOC-FIELDLIST
  imports MINI-AUTODOC-FIELDLIST-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:Command </k>

  syntax Bool ::= isReturnDescription(Field) [function]
  rule isReturnDescription(returnField) => true
  rule isReturnDescription(returnsField) => true
  rule isReturnDescription(_:Field) => false [owise]

  syntax Bool ::= isReturnType(Field) [function]
  rule isReturnType(rtypeField) => true
  rule isReturnType(_:Field) => false [owise]

  syntax Bool ::= hasReturnDescription(Fields) [function]
  rule hasReturnDescription(.Fields) => false
  rule hasReturnDescription(F:Field ; FS:Fields)
    => isReturnDescription(F) orBool hasReturnDescription(FS)

  syntax Bool ::= hasReturnType(Fields) [function]
  rule hasReturnType(.Fields) => false
  rule hasReturnType(F:Field ; FS:Fields)
    => isReturnType(F) orBool hasReturnType(FS)

  rule <k> augmentReturn(FS:Fields, true, ANN:String)
        => addRtype(ANN)
       </k>
    requires hasReturnDescription(FS) andBool notBool hasReturnType(FS)

  rule <k> augmentReturn(FS:Fields, HASANN:Bool, _:String)
        => noRtype
       </k>
    requires (notBool HASANN)
      orBool (notBool hasReturnDescription(FS))
      orBool hasReturnType(FS)
endmodule
