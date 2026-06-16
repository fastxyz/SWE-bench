module MINI-DJANGO-GROUPBY-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax Source ::= rawSQL | externalCols | ordinary
  syntax Sources ::= ".Sources" | Source ";" Sources [right]

  syntax GroupCol ::= gcol(Id, Bool, Sources)
  syntax GroupCols ::= ".GroupCols" | GroupCol ";" GroupCols [right]

  syntax OrderEntry ::= order(Bool, GroupCols)
  syntax OrderEntries ::= ".OrderEntries" | OrderEntry ";" OrderEntries [right]

  syntax GroupCols ::= orderGroupCols(OrderEntries) [function]
                     | appendKept(GroupCols, GroupCols) [function]
  syntax Bool ::= keep(GroupCol) [function]
                | hasSourceMarker(Sources) [function]
  syntax KResult ::= GroupCols | Bool
endmodule

module MINI-DJANGO-GROUPBY
  imports MINI-DJANGO-GROUPBY-SYNTAX
  imports BOOL

  configuration <k> $PGM:GroupCols </k>

  rule hasSourceMarker(.Sources) => false
  rule hasSourceMarker(rawSQL ; _) => true
  rule hasSourceMarker(externalCols ; _) => true
  rule hasSourceMarker(ordinary ; SS) => hasSourceMarker(SS)

  rule keep(gcol(_, true, _)) => true
  rule keep(gcol(_, false, SS)) => hasSourceMarker(SS)

  rule appendKept(.GroupCols, ACC) => ACC
  rule appendKept(C ; CS, ACC) => C ; appendKept(CS, ACC)
    requires keep(C)
  rule appendKept(C ; CS, ACC) => appendKept(CS, ACC)
    requires notBool keep(C)

  rule orderGroupCols(.OrderEntries) => .GroupCols
  rule orderGroupCols(order(true, _) ; OS) => orderGroupCols(OS)
  rule orderGroupCols(order(false, CS) ; OS) =>
    appendKept(CS, orderGroupCols(OS))
endmodule
