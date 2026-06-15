module MINI-DJANGO-ORDERING-SYNTAX
  imports BOOL-SYNTAX

  syntax Name ::= "supply" | "product" | "parent" | "isnull" | "lower" | "bogus"
  syntax Field ::= "F_SUPPLY" | "F_PRODUCT" | "F_PARENT" | "F_TEXT" | "F_OTHER"
  syntax FieldOpt ::= "none" | "some" "(" Field ")"
  syntax Outcome ::= "field" "(" Field ")" | "missing" "(" Name ")"
  syntax Outcomes ::= ".Outcomes" | Outcome ";" Outcomes [right]
  syntax Result ::= "ok" | "err"
  syntax Exp ::= "validate" "(" Outcomes ")" | "#walk" "(" Outcomes "," FieldOpt ")"
  syntax KResult ::= Result | Bool
endmodule

module MINI-DJANGO-ORDERING
  imports MINI-DJANGO-ORDERING-SYNTAX
  imports BOOL

  configuration <k> $PGM:Exp </k>

  syntax Bool ::= "hasTransform" "(" Field "," Name ")" [function]
  syntax Bool ::= "hasLookup" "(" Field "," Name ")" [function]

  rule hasTransform(F_PARENT, isnull) => false
  rule hasLookup(F_PARENT, isnull) => true
  rule hasTransform(F_TEXT, lower) => true
  rule hasLookup(F_TEXT, lower) => false
  rule hasTransform(F_OTHER, bogus) => false
  rule hasLookup(F_OTHER, bogus) => false

  rule <k> validate(OS:Outcomes) => #walk(OS, none) ... </k>

  rule <k> #walk(.Outcomes, _:FieldOpt) => ok ... </k>
  rule <k> #walk(field(F:Field) ; REST:Outcomes, _:FieldOpt) => #walk(REST, some(F)) ... </k>

  rule <k> #walk(missing(_:Name) ; _:Outcomes, none) => err ... </k>

  rule <k> #walk(missing(N:Name) ; REST:Outcomes, some(F:Field)) => #walk(REST, some(F)) ... </k>
    requires hasTransform(F, N)

  rule <k> #walk(missing(N:Name) ; .Outcomes, some(F:Field)) => ok ... </k>
    requires notBool hasTransform(F, N) andBool hasLookup(F, N)

  rule <k> #walk(missing(N:Name) ; .Outcomes, some(F:Field)) => err ... </k>
    requires notBool hasTransform(F, N) andBool notBool hasLookup(F, N)

  rule <k> #walk(missing(N:Name) ; NEXT:Outcome ; REST:Outcomes, some(F:Field)) => err ... </k>
    requires notBool hasTransform(F, N)
endmodule
