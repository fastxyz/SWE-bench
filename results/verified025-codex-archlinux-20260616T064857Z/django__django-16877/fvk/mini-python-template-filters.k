module MINI-PYTHON-TEMPLATE-FILTERS-SYNTAX
  imports STRING-SYNTAX

  syntax Item  ::= raw(String) | safe(String)
  syntax Items ::= ".Items" | Item ";" Items [right]

  syntax Exp ::= "escapeseq" "(" Items ")"
               | "joinOff" "(" Exp "," String ")"
               | "joinOffEscaped" "(" Items "," String ")"
               | Items
               | Item

  syntax KResult ::= Items | Item
endmodule

module MINI-PYTHON-TEMPLATE-FILTERS
  imports MINI-PYTHON-TEMPLATE-FILTERS-SYNTAX
  imports STRING

  configuration <k> $PGM:Exp </k>

  syntax String ::= htmlEscape(String) [function]

  syntax Item ::= conditionalEscape(Item) [function]
  rule conditionalEscape(raw(S:String))  => safe(htmlEscape(S))
  rule conditionalEscape(safe(S:String)) => safe(S)

  syntax Items ::= escapeSeq(Items) [function]
  rule escapeSeq(.Items) => .Items
  rule escapeSeq(I:Item ; REST:Items) => conditionalEscape(I) ; escapeSeq(REST)

  syntax String ::= joinSafe(Items, String) [function]
  rule joinSafe(.Items, SEP:String) => ""
  rule joinSafe(safe(S:String) ; .Items, SEP:String) => S
  rule joinSafe(safe(S:String) ; (safe(T:String) ; REST:Items), SEP:String)
    => S +String SEP +String joinSafe(safe(T) ; REST, SEP)

  rule <k> escapeseq(L:Items) => escapeSeq(L) ... </k>
  rule <k> joinOff(escapeseq(L:Items), SEP:String)
        => joinOffEscaped(escapeSeq(L), SEP) ... </k>
  rule <k> joinOffEscaped(L:Items, SEP:String)
        => safe(joinSafe(L, SEP)) ... </k>
endmodule
