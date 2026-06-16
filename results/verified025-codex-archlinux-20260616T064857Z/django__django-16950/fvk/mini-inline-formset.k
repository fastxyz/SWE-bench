module MINI-INLINE-FORMSET-SYNTAX
  imports BOOL-SYNTAX

  syntax FieldKind ::= "pkField" | "altField"
  syntax Value ::= "noneValue" | "someValue"
  syntax Step ::= "addFields" "(" Bool "," FieldKind "," Bool "," Value ")"
                | "initInlineField" "(" Bool "," Value "," Value ")"
  syntax KResult ::= Value | Bool
endmodule

module MINI-INLINE-FORMSET
  imports MINI-INLINE-FORMSET-SYNTAX
  imports BOOL

  configuration
    <k> $PGM:Step </k>
    <parentTarget> noneValue </parentTarget>
    <fieldInitial> noneValue </fieldInitial>
    <parentMutated> false </parentMutated>

  // Adding a parent whose relation target is a defaulted primary key preserves
  // Django's existing behavior: clear the parent value and render an empty
  // hidden inline value.
  rule
    <k> addFields(true, pkField, true, _V:Value) => .K </k>
    <parentTarget> _ => noneValue </parentTarget>
    <fieldInitial> _ => noneValue </fieldInitial>
    <parentMutated> _ => true </parentMutated>

  // Adding a parent whose relation target is a defaulted alternate key is the
  // bug-fix case: keep the parent value, but render an empty hidden inline
  // value so the unsaved generated key isn't posted back as stale data.
  rule
    <k> addFields(true, altField, true, V:Value) => .K </k>
    <parentTarget> _ => V </parentTarget>
    <fieldInitial> _ => noneValue </fieldInitial>
    <parentMutated> _ => false </parentMutated>

  // Non-default target values are copied into the inline field initial.
  rule
    <k> addFields(true, pkField, false, V:Value) => .K </k>
    <parentTarget> _ => V </parentTarget>
    <fieldInitial> _ => V </fieldInitial>
    <parentMutated> _ => false </parentMutated>

  rule
    <k> addFields(true, altField, false, V:Value) => .K </k>
    <parentTarget> _ => V </parentTarget>
    <fieldInitial> _ => V </fieldInitial>
    <parentMutated> _ => false </parentMutated>

  // Existing parents use their stored target value as the inline initial.
  rule
    <k> addFields(false, FK:FieldKind, HASDEFAULT:Bool, V:Value) => .K </k>
    <parentTarget> _ => V </parentTarget>
    <fieldInitial> _ => V </fieldInitial>
    <parentMutated> _ => false </parentMutated>

  // InlineForeignKeyField.__init__ now respects an explicit initial value.
  rule
    <k> initInlineField(true, _PARENT:Value, EXPLICIT:Value) => .K </k>
    <fieldInitial> _ => EXPLICIT </fieldInitial>

  // Without an explicit initial, it derives initial from the parent value.
  rule
    <k> initInlineField(false, PARENT:Value, _EXPLICIT:Value) => .K </k>
    <fieldInitial> _ => PARENT </fieldInitial>
endmodule
