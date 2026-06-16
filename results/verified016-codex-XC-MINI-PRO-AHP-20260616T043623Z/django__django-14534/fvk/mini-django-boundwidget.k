module MINI-DJANGO-BOUNDWIDGET-SYNTAX
  imports STRING-SYNTAX
  imports MAP-SYNTAX

  syntax Action ::= "idForLabel" "(" Map ")"
  syntax KResult ::= String
endmodule

module MINI-DJANGO-BOUNDWIDGET
  imports MINI-DJANGO-BOUNDWIDGET-SYNTAX
  imports STRING
  imports MAP
  imports BOOL

  configuration <k> $PGM:Action </k>

  // Model of BoundWidget.id_for_label over the subwidget attrs map.
  rule <k> idForLabel(("id" |-> ID:String) REST:Map) => ID </k>
    requires notBool ("id" in_keys(REST))

  rule <k> idForLabel(ATTRS:Map) => "" </k>
    requires notBool ("id" in_keys(ATTRS))
endmodule
