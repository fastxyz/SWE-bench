module MINI-AUTODOC-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Name ::= String
  syntax Args ::= String
  syntax Ret ::= "noneRet" | ret(String)

  syntax Line ::= sig(Name, Args, Ret) | text(String)
  syntax Lines ::= noLines() | lines(Line, Lines)
  syntax Names ::= noNames() | names(Name, Names)
  syntax Pair ::= pair(Args, Ret)
  syntax Pairs ::= noPairs() | pairs(Pair, Pairs)
  syntax Docs ::= noDocs() | docs(Lines, Docs)

  syntax CollectResult ::= collected(Pairs, Lines)
  syntax FindResult ::= found(Pairs, Docs) | noMatch(Docs)
  syntax MaybePair ::= somePair(Pair) | nonePair()

  syntax Task ::= findTask(Names, Docs)
                | firstTask(Names, Docs)
                | formatTask(Pairs)
                | explicitTask(String)

  syntax KResult ::= FindResult | MaybePair | String
endmodule

module MINI-AUTODOC
  imports MINI-AUTODOC-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:Task </k>

  syntax Bool ::= contains(Name, Names) [function]
  rule contains(N, noNames()) => false
  rule contains(N, names(N, _)) => true
  rule contains(N, names(M, NS)) => contains(N, NS)
    requires N =/=String M

  syntax Bool ::= nonEmpty(Pairs) [function]
  rule nonEmpty(noPairs()) => false
  rule nonEmpty(pairs(_, _)) => true

  syntax CollectResult ::= collect(Names, Lines) [function]
  syntax CollectResult ::= prepend(Pair, CollectResult) [function]

  rule prepend(P, collected(PS, Rest)) => collected(pairs(P, PS), Rest)

  rule collect(_, noLines()) => collected(noPairs(), noLines())
  rule collect(NS, lines(sig(B, A, R), LS))
    => prepend(pair(A, R), collect(NS, LS))
    requires contains(B, NS)
  rule collect(NS, lines(sig(B, A, R), LS))
    => collected(noPairs(), lines(sig(B, A, R), LS))
    requires notBool contains(B, NS)
  rule collect(_, lines(text(T), LS))
    => collected(noPairs(), lines(text(T), LS))

  syntax FindResult ::= find(Names, Docs) [function]
  syntax FindResult ::= keepDoc(Lines, FindResult) [function]

  rule find(_, noDocs()) => noMatch(noDocs())
  rule find(NS, docs(LS, DS)) => found(PS, docs(Rest, DS))
    requires collect(NS, LS) ==K collected(PS, Rest)
     andBool nonEmpty(PS)
  rule find(NS, docs(LS, DS)) => keepDoc(LS, find(NS, DS))
    requires collect(NS, LS) ==K collected(noPairs(), LS)
  rule keepDoc(LS, found(PS, DS)) => found(PS, docs(LS, DS))
  rule keepDoc(LS, noMatch(DS)) => noMatch(docs(LS, DS))

  syntax MaybePair ::= first(FindResult) [function]
  rule first(found(pairs(P, _), _)) => somePair(P)
  rule first(noMatch(_)) => nonePair()

  syntax String ::= format(Pairs) [function]
  syntax String ::= formatOne(Pair) [function]
  rule format(noPairs()) => ""
  rule format(pairs(P, noPairs())) => formatOne(P)
  rule format(pairs(P, pairs(Q, QS)))
    => formatOne(P) +String "\n" +String format(pairs(Q, QS))

  rule formatOne(pair(A, noneRet)) => "(" +String A +String ")"
  rule formatOne(pair(A, ret(R))) => "(" +String A +String ") -> " +String R

  rule <k> findTask(NS, DS) => find(NS, DS) </k>
  rule <k> firstTask(NS, DS) => first(find(NS, DS)) </k>
  rule <k> formatTask(PS) => format(PS) </k>
  rule <k> explicitTask(S) => S </k>
endmodule
