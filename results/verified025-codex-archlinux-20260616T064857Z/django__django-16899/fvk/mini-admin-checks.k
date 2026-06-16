module MINI-ADMIN-CHECKS-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax Label ::= readonlyLabel(Int)
                 | explicitLabel(String)

  syntax Msg ::= readonlyE035(Label, String, String, String)

  syntax Result ::= noErrors
                  | oneError(String, Msg)

  syntax Check ::= checkReadonlyFieldsItem(
                     String, String, String, Label, Bool, Bool, Bool, Bool
                   )
                 | checkReadonlyFieldsAt(
                     String, String, String, Int, Bool, Bool, Bool, Bool
                   )

  syntax KResult ::= Result
endmodule

module MINI-ADMIN-CHECKS
  imports MINI-ADMIN-CHECKS-SYNTAX
  imports BOOL
  imports INT
  imports STRING

  configuration <k> $PGM:Check </k>

  // checkReadonlyFieldsAt models the caller-created label
  // "readonly_fields[index]" without relying on string concatenation.
  rule <k> checkReadonlyFieldsAt(
             ADMIN:String, MODEL:String, FIELD:String, INDEX:Int,
             ISCALLABLE:Bool, HASADMIN:Bool, HASMODEL:Bool, HASFIELD:Bool
           )
        => checkReadonlyFieldsItem(
             ADMIN, MODEL, FIELD, readonlyLabel(INDEX),
             ISCALLABLE, HASADMIN, HASMODEL, HASFIELD
           )
        ... </k>

  rule <k> checkReadonlyFieldsItem(
             ADMIN:String, MODEL:String, FIELD:String, LABEL:Label,
             true, HASADMIN:Bool, HASMODEL:Bool, HASFIELD:Bool
           )
        => noErrors
        ... </k>

  rule <k> checkReadonlyFieldsItem(
             ADMIN:String, MODEL:String, FIELD:String, LABEL:Label,
             false, true, HASMODEL:Bool, HASFIELD:Bool
           )
        => noErrors
        ... </k>

  rule <k> checkReadonlyFieldsItem(
             ADMIN:String, MODEL:String, FIELD:String, LABEL:Label,
             false, false, true, HASFIELD:Bool
           )
        => noErrors
        ... </k>

  rule <k> checkReadonlyFieldsItem(
             ADMIN:String, MODEL:String, FIELD:String, LABEL:Label,
             false, false, false, true
           )
        => noErrors
        ... </k>

  rule <k> checkReadonlyFieldsItem(
             ADMIN:String, MODEL:String, FIELD:String, LABEL:Label,
             false, false, false, false
           )
        => oneError("admin.E035", readonlyE035(LABEL, FIELD, ADMIN, MODEL))
        ... </k>
endmodule
