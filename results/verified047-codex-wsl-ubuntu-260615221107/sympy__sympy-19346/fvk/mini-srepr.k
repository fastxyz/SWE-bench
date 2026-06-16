module MINI-SREPR-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Obj ::= atom(String)
               | dict(Pairs)
               | set(Objs)
               | frozenset(Objs)
               | list(Objs)
               | tuple(Objs)

  syntax Objs ::= ".Objs"
                | Obj ";" Objs [right]

  syntax Pair ::= pair(Obj, Obj)

  syntax Pairs ::= ".Pairs"
                 | Pair ";" Pairs [right]

  syntax Text ::= atomSrepr(String)
                | atomStr(String)
                | listText(Texts)
                | tupleText(Texts)
                | dictText(PairTexts)
                | setText(Texts)
                | emptySetText()
                | frozensetText(Text)

  syntax Texts ::= ".Texts"
                 | Text ";" Texts [right]

  syntax PairText ::= pairText(Text, Text)

  syntax PairTexts ::= ".PairTexts"
                     | PairText ";" PairTexts [right]

  syntax Cmd ::= srepr(Obj)
               | printDict(Pairs)
               | printSet(Objs)
               | printFrozenSet(Objs)

  syntax KResult ::= Text
endmodule

module MINI-SREPR
  imports MINI-SREPR-SYNTAX

  configuration <k> $PGM:Cmd </k>

  // Spec-level helpers. sortObjs/sortPairs model SymPy default_sort_key order.
  // atomSrepr(A) and atomStr(A) are intentionally distinct so the model can
  // observe the reported defect: legacy container fallback used atomStr-like
  // rendering for contained SymPy objects instead of atomSrepr-like rendering.
  syntax Objs ::= sortObjs(Objs) [function]
  syntax Pairs ::= sortPairs(Pairs) [function]
  syntax Bool ::= isEmptyObjs(Objs) [function]
  syntax Bool ::= hasNoDuplicateKeys(Pairs) [function]

  syntax Text ::= sreprObj(Obj) [function]
  syntax Texts ::= sreprObjs(Objs) [function]
  syntax PairTexts ::= sreprPairs(Pairs) [function]

  rule isEmptyObjs(.Objs) => true
  rule isEmptyObjs(_:Obj ; _:Objs) => false

  rule sreprObj(atom(A)) => atomSrepr(A)
  rule sreprObj(list(OS)) => listText(sreprObjs(OS))
  rule sreprObj(tuple(OS)) => tupleText(sreprObjs(OS))
  rule sreprObj(dict(PS)) => dictText(sreprPairs(sortPairs(PS)))
  rule sreprObj(set(.Objs)) => emptySetText()
  rule sreprObj(set(OS)) => setText(sreprObjs(sortObjs(OS)))
    requires isEmptyObjs(OS) ==Bool false
  rule sreprObj(frozenset(.Objs)) => frozensetText(emptySetText())
  rule sreprObj(frozenset(OS)) => frozensetText(setText(sreprObjs(sortObjs(OS))))
    requires isEmptyObjs(OS) ==Bool false

  rule sreprObjs(.Objs) => .Texts
  rule sreprObjs(O ; OS) => sreprObj(O) ; sreprObjs(OS)

  rule sreprPairs(.Pairs) => .PairTexts
  rule sreprPairs(pair(K, V) ; PS) => pairText(sreprObj(K), sreprObj(V)) ; sreprPairs(PS)

  rule <k> srepr(O) => sreprObj(O) </k>
  rule <k> printDict(PS) => dictText(sreprPairs(sortPairs(PS))) </k>
    requires hasNoDuplicateKeys(PS)
  rule <k> printSet(.Objs) => emptySetText() </k>
  rule <k> printSet(OS) => setText(sreprObjs(sortObjs(OS))) </k>
    requires isEmptyObjs(OS) ==Bool false
  rule <k> printFrozenSet(.Objs) => frozensetText(emptySetText()) </k>
  rule <k> printFrozenSet(OS) => frozensetText(setText(sreprObjs(sortObjs(OS)))) </k>
    requires isEmptyObjs(OS) ==Bool false
endmodule
