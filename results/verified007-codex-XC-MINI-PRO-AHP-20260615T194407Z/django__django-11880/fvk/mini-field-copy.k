module MINI-FIELD-COPY-SYNTAX
  imports INT-SYNTAX

  syntax Obj ::= FieldObj(Int, Int, Int)
               | WidgetObj(Int)
               | ErrorMessagesObj(Int)
               | ValidatorsObj(Int)

  syntax Exp ::= deepcopyField(Int)

  syntax KResult ::= Int
endmodule

module MINI-FIELD-COPY
  imports MINI-FIELD-COPY-SYNTAX
  imports INT
  imports BOOL
  imports MAP

  configuration
    <k> $PGM:Exp </k>
    <heap> .Map </heap>
    <next> 0 </next>

  // Model of django.forms.fields.Field.__deepcopy__ after the V1 fix.
  // The source field F references existing widget, error_messages, and validators
  // objects. A deep copy returns a fresh field id N. The copied field receives
  // fresh object ids for the widget, error_messages mapping, and validators list.
  rule
    <k> deepcopyField(F:Int) => N ... </k>
    <heap>
      H:Map
      =>
      H
        [N <- FieldObj(N +Int 1, N +Int 2, N +Int 3)]
        [(N +Int 1) <- WidgetObj(WP)]
        [(N +Int 2) <- ErrorMessagesObj(EP)]
        [(N +Int 3) <- ValidatorsObj(VP)]
    </heap>
    <next> N => N +Int 4 </next>
    requires H[F] ==K FieldObj(WO:Int, EO:Int, VO:Int)
     andBool H[WO] ==K WidgetObj(WP:Int)
     andBool H[EO] ==K ErrorMessagesObj(EP:Int)
     andBool H[VO] ==K ValidatorsObj(VP:Int)
endmodule
