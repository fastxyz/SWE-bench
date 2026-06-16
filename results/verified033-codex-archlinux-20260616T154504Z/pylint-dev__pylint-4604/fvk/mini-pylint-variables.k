requires "domains.md"

module MINI-PYLINT-VARIABLES-SYNTAX
  imports STRING-SYNTAX

  syntax Ann ::= Name(String)
               | Attr(Ann, String)
               | Sub(Ann, Ann)
               | Other

  syntax MaybeString ::= noAlias | alias(String)
endmodule

module MINI-PYLINT-VARIABLES
  imports MINI-PYLINT-VARIABLES-SYNTAX
  imports STRING
  imports BOOL
  imports SET

  syntax Set ::= collect(Ann) [function]
  syntax Set ::= qnames(Ann, String) [function]
  syntax String ::= fullName(Ann) [function]
  syntax Bool ::= hasQualifiedBase(Ann) [function]
  syntax Bool ::= isTypeUsed(String, MaybeString, Set) [function]

  rule collect(Name(N)) => SetItem(N)
  rule collect(Other) => .Set
  rule collect(Attr(BASE, FIELD)) => collect(BASE) unionSet qnames(BASE, FIELD)
  rule collect(Sub(VALUE, ARG)) => collect(VALUE) unionSet collect(ARG)

  rule qnames(Name(BASE), FIELD) => SetItem(BASE) unionSet SetItem(BASE +String "." +String FIELD)
  rule qnames(Attr(BASE, MID), FIELD) => qnames(BASE, MID) unionSet SetItem(fullName(Attr(BASE, MID)) +String "." +String FIELD)
    requires hasQualifiedBase(BASE)
  rule qnames(Attr(BASE, _MID), _FIELD) => .Set
    requires notBool hasQualifiedBase(BASE)
  rule qnames(Other, _FIELD) => .Set
  rule qnames(Sub(_VALUE, _ARG), _FIELD) => .Set

  rule fullName(Name(N)) => N
  rule fullName(Attr(BASE, FIELD)) => fullName(BASE) +String "." +String FIELD
  rule fullName(Other) => ""
  rule fullName(Sub(_VALUE, _ARG)) => ""

  rule hasQualifiedBase(Name(_N)) => true
  rule hasQualifiedBase(Attr(BASE, _FIELD)) => hasQualifiedBase(BASE)
  rule hasQualifiedBase(Other) => false
  rule hasQualifiedBase(Sub(_VALUE, _ARG)) => false

  rule isTypeUsed(IMPORTED, _ALIAS, NAMES) => true
    requires IMPORTED in NAMES
  rule isTypeUsed(_IMPORTED, alias(ALIAS), NAMES) => true
    requires ALIAS in NAMES
  rule isTypeUsed(IMPORTED, noAlias, NAMES) => false
    requires notBool (IMPORTED in NAMES)
  rule isTypeUsed(IMPORTED, alias(ALIAS), NAMES) => false
    requires notBool (IMPORTED in NAMES) andBool notBool (ALIAS in NAMES)
endmodule
