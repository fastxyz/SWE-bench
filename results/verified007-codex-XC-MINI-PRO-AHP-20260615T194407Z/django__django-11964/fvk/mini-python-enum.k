module MINI-PYTHON-ENUM-SYNTAX
  imports STRING-SYNTAX
  imports INT-SYNTAX

  syntax Value ::= SVal(String) | IVal(Int)
  syntax ChoiceMember ::= Choice(String, Value)
  syntax StoredValue ::= Created(ChoiceMember) | Retrieved(Value)
  syntax Text ::= text(String) | intText(Int) | enumText(String) | valueText(Value) [function]
  syntax TextPair ::= pair(Text, Text)
  syntax Exp ::= CreateThenStr(ChoiceMember)
               | RetrieveThenStr(Value)
               | CreatedRetrievedTexts(ChoiceMember)
               | StrOf(StoredValue)
               | ReprOf(ChoiceMember)
  syntax KResult ::= Text | TextPair
endmodule

module MINI-PYTHON-ENUM
  imports MINI-PYTHON-ENUM-SYNTAX
  imports STRING
  imports INT

  configuration <k> $PGM:Exp </k>

  rule valueText(SVal(S:String)) => text(S)
  rule valueText(IVal(I:Int)) => intText(I)

  rule <k> CreateThenStr(M:ChoiceMember) => StrOf(Created(M)) ... </k>
  rule <k> RetrieveThenStr(V:Value) => StrOf(Retrieved(V)) ... </k>

  // V1 behavior: Choices.__str__ returns str(self.value), not Enum.__str__.
  rule <k> StrOf(Created(Choice(NAME:String, V:Value))) => valueText(V) ... </k>

  // Database-retrieved model instances already hold the primitive value.
  rule <k> StrOf(Retrieved(V:Value)) => valueText(V) ... </k>

  // Combined observable: created and retrieved paths render the same text.
  rule <k> CreatedRetrievedTexts(Choice(NAME:String, V:Value)) => pair(valueText(V), valueText(V)) ... </k>

  // Frame model: repr-style enum identity remains enum-name based.
  rule <k> ReprOf(Choice(NAME:String, V:Value)) => enumText(NAME) ... </k>
endmodule
