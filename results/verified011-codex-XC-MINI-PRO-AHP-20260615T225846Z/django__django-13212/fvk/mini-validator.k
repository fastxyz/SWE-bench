// Constructed, not machine-checked.
// Minimal K-style semantics for the validator property audited here.
// This abstracts Python control flow into validator outcomes while preserving
// the observable axis under verification: ValidationError.params.

module MINI-VALIDATOR-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  imports MAP-SYNTAX

  syntax Validator ::= "regex" | "url" | "email" | "ipv4" | "ipv6" | "ipv46"
                     | "base" | "decimal" | "file-extension" | "null-chars"
                     | "keys"
  syntax Value
  syntax Outcome ::= "ok"
                   | "error" "(" Id "," Id "," Map ")"

  syntax KItem ::= "validate" "(" Validator "," Value ")"

  syntax Bool ::= "isInvalid" "(" Validator "," Value ")" [function]
  syntax Id ::= "messageOf" "(" Validator ")" [function]
              | "codeOf" "(" Validator ")" [function]
  syntax Map ::= "baseParams" "(" Validator "," Value ")" [function]
               | "withValue" "(" Map "," Value ")" [function]
endmodule

module MINI-VALIDATOR
  imports MINI-VALIDATOR-SYNTAX
  imports BOOL
  imports MAP

  configuration <k> $PGM:K </k>

  rule withValue(PARAMS:Map, VALUE:Value) => PARAMS [ value <- VALUE ]

  rule <k> validate(VALIDATOR:Validator, VALUE:Value)
        => error(messageOf(VALIDATOR), codeOf(VALIDATOR),
                 withValue(baseParams(VALIDATOR, VALUE), VALUE)) ... </k>
    requires isInvalid(VALIDATOR, VALUE)

  rule <k> validate(VALIDATOR:Validator, VALUE:Value) => ok ... </k>
    requires notBool isInvalid(VALIDATOR, VALUE)
endmodule
