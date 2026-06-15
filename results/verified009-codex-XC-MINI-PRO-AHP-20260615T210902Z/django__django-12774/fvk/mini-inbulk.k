module MINI-INBULK-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Verdict ::= allow | reject
  syntax Field ::= field(String, String, Bool)
  syntax Constraint ::= uc(String, Bool)
  syntax Constraints ::= ".Constraints"
                       | Constraint "," Constraints [right]
  syntax Exp ::= validate(String, Field, Constraints)
  syntax Bool ::= singleTotalMatches(String, String, Constraints) [function]
  syntax KResult ::= Verdict | Bool
endmodule

module MINI-INBULK
  imports MINI-INBULK-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:Exp </k>

  rule singleTotalMatches(NAME:String, ATT:String, .Constraints) => false
  rule singleTotalMatches(NAME:String, ATT:String, uc(ID:String, true), CS:Constraints)
    => ((ID ==String NAME) orBool (ID ==String ATT)) orBool singleTotalMatches(NAME, ATT, CS)
  rule singleTotalMatches(NAME:String, ATT:String, uc(_:String, false), CS:Constraints)
    => singleTotalMatches(NAME, ATT, CS)

  rule <k> validate("pk", field(_:String, _:String, _:Bool), _:Constraints) => allow ... </k>
  rule <k> validate(FIELDNAME:String, field(_:String, _:String, true), _:Constraints) => allow ... </k>
    requires FIELDNAME =/=String "pk"
  rule <k> validate(FIELDNAME:String, field(NAME:String, ATT:String, false), CS:Constraints) => allow ... </k>
    requires FIELDNAME =/=String "pk"
     andBool singleTotalMatches(NAME, ATT, CS)
  rule <k> validate(FIELDNAME:String, field(NAME:String, ATT:String, false), CS:Constraints) => reject ... </k>
    requires FIELDNAME =/=String "pk"
     andBool notBool singleTotalMatches(NAME, ATT, CS)
endmodule
