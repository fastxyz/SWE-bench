module MINI-DJANGO-FORMS-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Val ::= String
  syntax MaybeBool ::= "none" | "some" "(" Bool ")"
  syntax Field ::= "field" "(" Bool ")"
  syntax Exp ::= Val
               | Field
               | Bool
               | "defaultRPHF" "(" MaybeBool ")"
               | "disabledOf" "(" Exp ")" [strict(1)]
               | "cleanPassword" "(" Exp "," Val "," Val ")" [strict(1)]

  syntax KResult ::= Val | Field | Bool
endmodule

module MINI-DJANGO-FORMS
  imports MINI-DJANGO-FORMS-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:Exp </k>

  // ReadOnlyPasswordHashField.__init__ applies kwargs.setdefault("disabled", True).
  rule <k> defaultRPHF(none) => field(true) </k>

  // setdefault preserves an explicit disabled kwarg supplied by the caller.
  rule <k> defaultRPHF(some(B:Bool)) => field(B) </k>

  rule <k> disabledOf(field(B:Bool)) => B </k>

  // BaseForm._clean_fields() ignores submitted data for disabled fields and
  // uses get_initial_for_field() instead.
  rule <k> cleanPassword(field(true), SUB:Val, INIT:Val) => INIT </k>

  // This branch represents the public opt-out: explicit disabled=False keeps
  // normal submitted-data cleaning behavior.
  rule <k> cleanPassword(field(false), SUB:Val, INIT:Val) => SUB </k>
endmodule
