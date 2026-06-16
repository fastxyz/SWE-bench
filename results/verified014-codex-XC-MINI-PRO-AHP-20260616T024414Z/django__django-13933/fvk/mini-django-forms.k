module MINI-DJANGO-FORMS-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX

  syntax Value ::= "emptyValue" "(" ")"
                 | "submitted" "(" String ")"
                 | "modelInstance" "(" String ")"
                 | "object" "(" String ")"
                 | "badType" "(" String ")"

  syntax Message ::= "modelChoiceInvalid" "(" ")"
                   | "customInvalid" "(" String ")"

  syntax Outcome ::= "ok" "(" Value ")"
                   | "validationError" "(" String "," String "," Map ")"

  syntax KItem ::= "modelChoiceToPython" "(" Value ")"
                 | "queryGet" "(" Value ")"
                 | "invalidChoice" "(" Value ")"

  syntax String ::= "render" "(" Message "," Value ")" [function]
                  | "show" "(" Value ")" [function]
endmodule

module MINI-DJANGO-FORMS
  imports MINI-DJANGO-FORMS-SYNTAX
  imports STRING
  imports BOOL
  imports MAP

  configuration
    <k> $PGM:K </k>
    <queryset> .Map </queryset>
    <errorMessage> modelChoiceInvalid() </errorMessage>

  rule show(emptyValue()) => ""
  rule show(submitted(S:String)) => S
  rule show(modelInstance(S:String)) => S
  rule show(object(S:String)) => S
  rule show(badType(S:String)) => S

  rule render(modelChoiceInvalid(), V:Value)
    => "Select a valid choice. " +String show(V) +String " is not one of the available choices."
  rule render(customInvalid(S:String), _V:Value) => S

  rule <k> modelChoiceToPython(emptyValue()) => ok(emptyValue()) ... </k>

  rule <k> modelChoiceToPython(submitted(K:String)) => queryGet(submitted(K)) ... </k>
  rule <k> modelChoiceToPython(modelInstance(K:String)) => queryGet(submitted(K)) ... </k>
  rule <k> modelChoiceToPython(badType(K:String)) => invalidChoice(badType(K)) ... </k>

  rule <k> queryGet(submitted(K:String)) => ok(OBJ) ... </k>
       <queryset> ... K |-> OBJ:Value ... </queryset>

  rule <k> queryGet(submitted(K:String)) => invalidChoice(submitted(K)) ... </k>
       <queryset> QS:Map </queryset>
    requires notBool(K in_keys(QS))

  rule <k> invalidChoice(V:Value)
        => validationError("invalid_choice", render(MSG, V), "value" |-> V)
        ... </k>
       <errorMessage> MSG:Message </errorMessage>
endmodule
