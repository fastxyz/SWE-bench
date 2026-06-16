module MINI-INSPECTDB-SYNTAX
  imports STRING-SYNTAX
  imports MAP-SYNTAX

  syntax Exp ::= relationExtraParams(String, String, String)
  syntax KResult ::= Map
endmodule

module MINI-INSPECTDB
  imports MINI-INSPECTDB-SYNTAX
  imports STRING
  imports MAP

  configuration <k> $PGM:Exp </k>

  // Abstract model of the inspected relation parameter decision:
  // relationExtraParams(RelColumn, TargetPk, TargetFieldName)
  rule <k> relationExtraParams(Rel:String, Rel:String, Target:String)
        => .Map
       </k>

  rule <k> relationExtraParams(Rel:String, Pk:String, Target:String)
        => "to_field" |-> Target
       </k>
    requires Rel =/=String Pk
endmodule
