requires "mini-python-slots.k"

module SYMBOL-SLOTS-SPEC
  imports MINI-PYTHON-SLOTS

  // SPEC-PROVENANCE:
  // - from_prompt: "Symbol instances had no __dict__ attribute" =>
  //   Symbol must not inherit an instance dictionary.
  // - from_prompt: "introduced because some parent class accidentally stopped
  //   defining __slots__" and "we should add empty slots to DefaultPrinting" =>
  //   the printing mixin must contribute EmptySlots rather than NoSlots.
  // - from_code: DefaultPrinting is an alias for Printable in
  //   sympy/printing/defaults.py, and Basic inherits Printable directly.
  rule slotOf(Printable) => EmptySlots
  rule basesOf(Printable) => .Classes

  rule slotOf(Basic) => NamedSlots
  rule basesOf(Basic) => Printable , .Classes

  rule slotOf(Expr) => EmptySlots
  rule basesOf(Expr) => Basic , .Classes

  rule slotOf(Atom) => EmptySlots
  rule basesOf(Atom) => Basic , .Classes

  rule slotOf(AtomicExpr) => EmptySlots
  rule basesOf(AtomicExpr) => Atom , Expr , .Classes

  rule slotOf(Boolean) => EmptySlots
  rule basesOf(Boolean) => Basic , .Classes

  rule slotOf(Symbol) => NamedSlots
  rule basesOf(Symbol) => AtomicExpr , Boolean , .Classes

  // A public compatibility check from the issue discussion: adding empty
  // slots to the mixin does not remove __dict__ from subclasses that omit
  // __slots__, because those subclasses provide their own instance dict.
  rule slotOf(ExternalNoSlotsSubclass) => NoSlots
  rule basesOf(ExternalNoSlotsSubclass) => Printable , .Classes

  claim <k> hasInstanceDict(Basic) => false </k> [all-path]
  claim <k> hasInstanceDict(Symbol) => false </k> [all-path]
  claim <k> hasInstanceDict(ExternalNoSlotsSubclass) => true </k> [all-path]
endmodule
