module MINI-PYTHON-CHARFIELD-SYNTAX
  imports INT-SYNTAX

  syntax Limit ::= Int
                 | "invalidLimit"

  syntax MaxLength ::= "none"
                     | "some" "(" Limit ")"

  syntax Validator ::= "MaxLengthValidator" "(" MaxLength ")"

  syntax Validators ::= ".Validators"
                      | Validators ";" Validator [left]

  syntax FieldObj ::= "field" "(" MaxLength "," Validators ")"

  syntax Command ::= "charField" "(" MaxLength "," Validators ")"
                   | "resolveValueString"

  syntax KResult ::= FieldObj
endmodule

module MINI-PYTHON-CHARFIELD
  imports MINI-PYTHON-CHARFIELD-SYNTAX

  configuration <k> $PGM:Command </k>

  // Model of V1 CharField.__init__ for the validator-state observable.
  rule <k> charField(none, VS:Validators) => field(none, VS) </k>
  rule <k> charField(some(L:Limit), VS:Validators)
        => field(some(L), VS ; MaxLengthValidator(some(L))) </k>

  // Model of Value._resolve_output_field() for str values.
  rule <k> resolveValueString => charField(none, .Validators) </k>
endmodule
