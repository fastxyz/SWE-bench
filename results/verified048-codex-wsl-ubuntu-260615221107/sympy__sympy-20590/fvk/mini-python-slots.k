module MINI-PYTHON-SLOTS-SYNTAX
  imports BOOL-SYNTAX

  syntax ClassName ::= "Printable"
                     | "Basic"
                     | "Expr"
                     | "Atom"
                     | "AtomicExpr"
                     | "Boolean"
                     | "Symbol"
                     | "ExternalNoSlotsSubclass"

  syntax SlotDecl ::= "NoSlots" | "EmptySlots" | "NamedSlots"
  syntax Classes ::= ".Classes" | ClassName "," Classes [right]

  syntax Bool ::= "hasOwnDict" "(" SlotDecl ")" [function]
                | "anyBaseHasDict" "(" Classes ")" [function]
                | "hasInstanceDict" "(" ClassName ")" [function]
  syntax SlotDecl ::= "slotOf" "(" ClassName ")" [function]
  syntax Classes ::= "basesOf" "(" ClassName ")" [function]
endmodule

module MINI-PYTHON-SLOTS
  imports MINI-PYTHON-SLOTS-SYNTAX
  imports BOOL

  configuration <k> $PGM:Bool </k>

  rule hasOwnDict(NoSlots) => true
  rule hasOwnDict(EmptySlots) => false
  rule hasOwnDict(NamedSlots) => false

  rule anyBaseHasDict(.Classes) => false
  rule anyBaseHasDict(C:ClassName , CS:Classes)
    => hasInstanceDict(C) orBool anyBaseHasDict(CS)

  rule hasInstanceDict(C:ClassName)
    => hasOwnDict(slotOf(C)) orBool anyBaseHasDict(basesOf(C))
endmodule
