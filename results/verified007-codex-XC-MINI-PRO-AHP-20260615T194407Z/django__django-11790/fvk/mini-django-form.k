module MINI-DJANGO-FORM-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax LengthOpt ::= noLength() | someLength(Int)
  syntax FieldKind ::= usernameField() | charField() | otherField()
  syntax LabelOpt ::= noLabel() | labelText(String)
  syntax AttrValue ::= lenAttr(Int) | textAttr(String)

  syntax Stmt ::= initAuth(LengthOpt, FieldKind, Bool, LabelOpt, String)
endmodule

module MINI-DJANGO-FORM
  imports MINI-DJANGO-FORM-SYNTAX
  imports INT
  imports BOOL
  imports STRING
  imports MAP

  configuration
    <k> $PGM:Stmt </k>
    <maxLength> 0 </maxLength>
    <attrs> .Map </attrs>
    <label> noLabel() </label>

  syntax Int ::= effectiveLength(LengthOpt) [function]
  rule effectiveLength(someLength(N)) => N requires N >Int 0
  rule effectiveLength(noLength()) => 254

  syntax Map ::= widgetAttrs(FieldKind, Bool, Int) [function]
  rule widgetAttrs(usernameField(), false, L)
    => "maxlength" |-> lenAttr(L)
       "autocapitalize" |-> textAttr("none")
       "autocomplete" |-> textAttr("username")
  rule widgetAttrs(usernameField(), true, L)
    => "autocapitalize" |-> textAttr("none")
       "autocomplete" |-> textAttr("username")
  rule widgetAttrs(charField(), false, L) => "maxlength" |-> lenAttr(L)
  rule widgetAttrs(charField(), true, L) => .Map
  rule widgetAttrs(otherField(), H, L) => .Map

  syntax Map ::= mergeAttrs(Map, Map) [function]
  rule mergeAttrs(A, .Map) => A
  rule mergeAttrs(A, K |-> V REST) => mergeAttrs(A [K <- V], REST)

  syntax LabelOpt ::= resolvedLabel(LabelOpt, String) [function]
  rule resolvedLabel(noLabel(), V) => labelText(V)
  rule resolvedLabel(labelText(S), V) => labelText(S)

  rule
    <k> initAuth(UML, KIND, HIDDEN, LABEL, VNAME) => .K </k>
    <maxLength> _ => effectiveLength(UML) </maxLength>
    <attrs> A => mergeAttrs(A, widgetAttrs(KIND, HIDDEN, effectiveLength(UML))) </attrs>
    <label> LABEL => resolvedLabel(LABEL, VNAME) </label>
endmodule
