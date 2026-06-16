module MINI-PYTHON-AUTOFIELD-SYNTAX
  imports BOOL-SYNTAX

  syntax Class ::= "autoField"
                 | "bigAutoField"
                 | "smallAutoField"
                 | "customBigAutoField"
                 | "customSmallAutoField"
                 | "indirectCustomBigAutoField"
                 | "customDirectAutoField"
                 | "textField"

  syntax ImportResult ::= "imported" "(" Class ")"
                        | "importError"
                        | "emptyPath"

  syntax CheckResult ::= "accepted" "(" Class ")"
                       | "valueError"
                       | "improperlyConfigured"

  syntax Bool ::= "subclassOf" "(" Class "," Class ")" [function]
                | "tupleSubclassCheck" "(" Class ")" [function]
                | "superAutoFieldSubclassCheck" "(" Class ")" [function]
                | "autoFieldSubclassCheck" "(" Class ")" [function]
                | "legacyExactTupleCheck" "(" Class ")" [function]

  syntax CheckResult ::= "defaultPkCheck" "(" ImportResult ")" [function]
endmodule

module MINI-PYTHON-AUTOFIELD
  imports MINI-PYTHON-AUTOFIELD-SYNTAX
  imports BOOL

  configuration <k> $PGM:K </k>

  // A small class hierarchy sufficient to distinguish the reported bug.
  rule subclassOf(C:Class, C:Class) => true
  rule subclassOf(customBigAutoField, bigAutoField) => true
  rule subclassOf(indirectCustomBigAutoField, customBigAutoField) => true
  rule subclassOf(indirectCustomBigAutoField, bigAutoField) => true
  rule subclassOf(customSmallAutoField, smallAutoField) => true
  rule subclassOf(customDirectAutoField, autoField) => true
  rule subclassOf(_:Class, _:Class) => false [owise]

  // V1 production code:
  // issubclass(subclass, (BigAutoField, SmallAutoField)) or
  // super().__subclasscheck__(subclass)
  rule tupleSubclassCheck(C:Class) =>
       subclassOf(C, bigAutoField) orBool subclassOf(C, smallAutoField)
  rule superAutoFieldSubclassCheck(C:Class) => subclassOf(C, autoField)
  rule autoFieldSubclassCheck(C:Class) =>
       tupleSubclassCheck(C) orBool superAutoFieldSubclassCheck(C)

  // Pre-fix exact membership behavior for the bug witness.
  rule legacyExactTupleCheck(bigAutoField) => true
  rule legacyExactTupleCheck(smallAutoField) => true
  rule legacyExactTupleCheck(_:Class) => false [owise]

  // The relevant part of Options._get_default_pk_class().
  rule defaultPkCheck(imported(C:Class)) => accepted(C)
    requires autoFieldSubclassCheck(C) ==Bool true
  rule defaultPkCheck(imported(C:Class)) => valueError
    requires autoFieldSubclassCheck(C) ==Bool false
  rule defaultPkCheck(importError) => improperlyConfigured
  rule defaultPkCheck(emptyPath) => improperlyConfigured
endmodule
