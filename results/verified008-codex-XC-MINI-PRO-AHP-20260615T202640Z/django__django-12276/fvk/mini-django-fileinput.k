module MINI-DJANGO-FILEINPUT-SYNTAX
  imports BOOL-SYNTAX

  syntax Initial ::= "initial" | "noInitial"
  syntax Widget ::= "GenericVisibleWidget"
                  | "GenericHiddenWidget"
                  | "FileInput"
                  | "ClearableFileInput"
                  | "AdminFileWidget"

  syntax Bool ::= hasInitial "(" Initial ")" [function]
                | isHidden "(" Widget ")" [function]
                | baseUseRequiredAttribute "(" Widget ")" [function]
                | useRequiredAttribute "(" Widget "," Initial ")" [function]
                | buildRequiredAttr "(" Widget "," Initial "," Bool "," Bool ")" [function]
endmodule

module MINI-DJANGO-FILEINPUT
  imports MINI-DJANGO-FILEINPUT-SYNTAX
  imports BOOL

  configuration <k> $PGM:Bool </k>

  rule hasInitial(initial) => true
  rule hasInitial(noInitial) => false

  rule isHidden(GenericVisibleWidget) => false
  rule isHidden(GenericHiddenWidget) => true
  rule isHidden(FileInput) => false
  rule isHidden(ClearableFileInput) => false
  rule isHidden(AdminFileWidget) => false

  rule baseUseRequiredAttribute(W:Widget) => notBool isHidden(W)

  // Generic widgets keep the base Widget rule.
  rule useRequiredAttribute(GenericVisibleWidget, I:Initial) => baseUseRequiredAttribute(GenericVisibleWidget)
  rule useRequiredAttribute(GenericHiddenWidget, I:Initial) => baseUseRequiredAttribute(GenericHiddenWidget)

  // V2 source rule: FileInput returns super().use_required_attribute(initial) and not initial.
  rule useRequiredAttribute(FileInput, I:Initial) =>
       baseUseRequiredAttribute(FileInput) andBool notBool hasInitial(I)

  // ClearableFileInput and AdminFileWidget inherit FileInput's rule.
  rule useRequiredAttribute(ClearableFileInput, I:Initial) => useRequiredAttribute(FileInput, I)
  rule useRequiredAttribute(AdminFileWidget, I:Initial) => useRequiredAttribute(FileInput, I)

  // BoundField.build_widget_attrs() contributes the field and form-level gates.
  rule buildRequiredAttr(W:Widget, I:Initial, FieldRequired:Bool, FormUseRequired:Bool) =>
       FieldRequired andBool FormUseRequired andBool useRequiredAttribute(W, I)
endmodule
