module MINI-DJANGO-FORMFIELD-SYNTAX
  imports BOOL-SYNTAX

  syntax WidgetKind ::= "radio" | "select" | "other"
  syntax MaybeWidget ::= "noWidget" | "widget" "(" WidgetKind ")"
  syntax EmptyArg ::= "noExplicitEmptyLabel" | "explicitEmptyLabel"
  syntax EmptyResult ::= "emptyNone" | "emptyDefault" | "emptyExplicit"
  syntax KResult ::= EmptyResult

  syntax Exp ::= "decideEmptyLabel" "(" Bool "," MaybeWidget "," WidgetKind "," EmptyArg ")"
endmodule

module MINI-DJANGO-FORMFIELD
  imports MINI-DJANGO-FORMFIELD-SYNTAX
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // Explicit empty_label is a caller override.
  rule <k> decideEmptyLabel(BLANK:Bool, W:MaybeWidget, DEFAULT:WidgetKind, explicitEmptyLabel)
        => emptyExplicit
        ... </k>

  // V2 rule: non-blank explicit radio widgets suppress the generated empty label.
  rule <k> decideEmptyLabel(false, widget(radio), DEFAULT:WidgetKind, noExplicitEmptyLabel)
        => emptyNone
        ... </k>

  // V2 rule: when no widget kwarg exists, a radio default on the form class is
  // still the effective widget and suppresses the generated empty label.
  rule <k> decideEmptyLabel(false, noWidget, radio, noExplicitEmptyLabel)
        => emptyNone
        ... </k>

  // If blank is true, blank remains a valid form value.
  rule <k> decideEmptyLabel(true, W:MaybeWidget, DEFAULT:WidgetKind, noExplicitEmptyLabel)
        => emptyDefault
        ... </k>

  // Non-radio explicit widgets preserve Django's normal ModelChoiceField default.
  rule <k> decideEmptyLabel(false, widget(select), DEFAULT:WidgetKind, noExplicitEmptyLabel)
        => emptyDefault
        ... </k>
  rule <k> decideEmptyLabel(false, widget(other), DEFAULT:WidgetKind, noExplicitEmptyLabel)
        => emptyDefault
        ... </k>

  // With no explicit widget, non-radio form-class defaults also preserve the
  // normal ModelChoiceField default.
  rule <k> decideEmptyLabel(false, noWidget, select, noExplicitEmptyLabel)
        => emptyDefault
        ... </k>
  rule <k> decideEmptyLabel(false, noWidget, other, noExplicitEmptyLabel)
        => emptyDefault
        ... </k>
endmodule
