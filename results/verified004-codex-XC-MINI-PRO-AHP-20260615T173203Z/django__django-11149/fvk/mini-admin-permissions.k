module MINI-ADMIN-PERMISSIONS-SYNTAX
  imports BOOL-SYNTAX

  syntax RelState ::= "originalRel" | "submittedRel"

  syntax AdminExp ::= Bool
                    | RelState
                    | "autoM2MView" "(" Bool "," Bool ")"
                    | "autoM2MWrite" "(" Bool ")"
                    | "applyInlinePost" "(" AdminExp "," RelState "," RelState ")" [strict(1)]

  syntax KResult ::= Bool | RelState
endmodule

module MINI-ADMIN-PERMISSIONS
  imports MINI-ADMIN-PERMISSIONS-SYNTAX
  imports BOOL

  configuration <k> $PGM:AdminExp </k>

  // Auto-created m2m intermediary view permission follows target view-or-change.
  rule <k> autoM2MView(TARGET_VIEW:Bool, TARGET_CHANGE:Bool)
        => TARGET_VIEW orBool TARGET_CHANGE
        ... </k>

  // Auto-created m2m intermediary writes follow target change, not target view.
  rule <k> autoM2MWrite(TARGET_CHANGE:Bool)
        => TARGET_CHANGE
        ... </k>

  // This abstracts the relevant formset save effect:
  // no write permission preserves the original relationship state.
  rule <k> applyInlinePost(false, ORIGINAL:RelState, SUBMITTED:RelState)
        => ORIGINAL
        ... </k>

  // With write permission, the submitted relationship state may be applied.
  rule <k> applyInlinePost(true, ORIGINAL:RelState, SUBMITTED:RelState)
        => SUBMITTED
        ... </k>
endmodule
