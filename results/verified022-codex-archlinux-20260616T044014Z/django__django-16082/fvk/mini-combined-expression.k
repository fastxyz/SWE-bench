module MINI-COMBINED-EXPRESSION-SYNTAX
  imports BOOL-SYNTAX

  syntax Connector ::= add | sub | mul | div | mod | pow
  syntax FieldType ::= integer | integerSub | decimal | float | other
  syntax MaybeField ::= noType | some(FieldType)
  syntax CExp ::= resolve(Connector, FieldType, FieldType)

  syntax Bool ::= sameNumericConnector(Connector) [function]
                | mixedNumericConnector(Connector) [function]
                | isIntegerFamily(FieldType) [function]
                | isDecimalFamily(FieldType) [function]
                | isFloatFamily(FieldType) [function]

  syntax KResult ::= Connector | FieldType | MaybeField | Bool
endmodule

module MINI-COMBINED-EXPRESSION
  imports MINI-COMBINED-EXPRESSION-SYNTAX
  imports BOOL

  configuration <k> $PGM:CExp </k>

  rule sameNumericConnector(add) => true
  rule sameNumericConnector(sub) => true
  rule sameNumericConnector(mul) => true
  rule sameNumericConnector(div) => true
  rule sameNumericConnector(mod) => true
  rule sameNumericConnector(pow) => true

  rule mixedNumericConnector(add) => true
  rule mixedNumericConnector(sub) => true
  rule mixedNumericConnector(mul) => true
  rule mixedNumericConnector(div) => true
  rule mixedNumericConnector(mod) => true
  rule mixedNumericConnector(pow) => false

  rule isIntegerFamily(integer) => true
  rule isIntegerFamily(integerSub) => true
  rule isIntegerFamily(decimal) => false
  rule isIntegerFamily(float) => false
  rule isIntegerFamily(other) => false

  rule isDecimalFamily(integer) => false
  rule isDecimalFamily(integerSub) => false
  rule isDecimalFamily(decimal) => true
  rule isDecimalFamily(float) => false
  rule isDecimalFamily(other) => false

  rule isFloatFamily(integer) => false
  rule isFloatFamily(integerSub) => false
  rule isFloatFamily(decimal) => false
  rule isFloatFamily(float) => true
  rule isFloatFamily(other) => false

  rule resolve(C, L, R) => some(integer)
    requires sameNumericConnector(C)
     andBool isIntegerFamily(L)
     andBool isIntegerFamily(R)

  rule resolve(C, L, R) => some(decimal)
    requires sameNumericConnector(C)
     andBool isDecimalFamily(L)
     andBool isDecimalFamily(R)

  rule resolve(C, L, R) => some(float)
    requires sameNumericConnector(C)
     andBool isFloatFamily(L)
     andBool isFloatFamily(R)

  rule resolve(C, L, R) => some(decimal)
    requires mixedNumericConnector(C)
     andBool isIntegerFamily(L)
     andBool isDecimalFamily(R)

  rule resolve(C, L, R) => some(decimal)
    requires mixedNumericConnector(C)
     andBool isDecimalFamily(L)
     andBool isIntegerFamily(R)

  rule resolve(C, L, R) => some(float)
    requires mixedNumericConnector(C)
     andBool isIntegerFamily(L)
     andBool isFloatFamily(R)

  rule resolve(C, L, R) => some(float)
    requires mixedNumericConnector(C)
     andBool isFloatFamily(L)
     andBool isIntegerFamily(R)

  rule resolve(pow, L, R) => noType
    requires isIntegerFamily(L) andBool isDecimalFamily(R)

  rule resolve(pow, L, R) => noType
    requires isDecimalFamily(L) andBool isIntegerFamily(R)

  rule resolve(pow, L, R) => noType
    requires isIntegerFamily(L) andBool isFloatFamily(R)

  rule resolve(pow, L, R) => noType
    requires isFloatFamily(L) andBool isIntegerFamily(R)
endmodule
