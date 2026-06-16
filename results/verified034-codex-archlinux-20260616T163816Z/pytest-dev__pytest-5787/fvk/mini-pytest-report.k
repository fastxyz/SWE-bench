module MINI-PYTEST-REPORT-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX
  imports LIST-SYNTAX
  imports MAP-SYNTAX

  syntax Entry ::= reprEntry(String, Map)
                 | nativeEntry(List)
  syntax Traceback ::= traceback(List, String, String)
  syntax Crash ::= crash(String, Int, String)
                 | noneCrash()
  syntax ChainElem ::= chainElem(Traceback, Crash, String)
  syntax Longrepr ::= reprInfo(Traceback, Crash, List)
                    | chainRepr(List, List)

  syntax JsonEntry ::= jsonEntry(String, Map)
                     | jsonNativeEntry(List)
  syntax JsonTraceback ::= jsonTraceback(List, String, String)
  syntax JsonCrash ::= jsonCrash(String, Int, String)
                     | jsonNoneCrash()
  syntax JsonChainElem ::= jsonChainElem(JsonTraceback, JsonCrash, String)
  syntax ChainField ::= noChain()
                      | someChain(List)
  syntax JsonLongrepr ::= jsonLongrepr(JsonTraceback, JsonCrash, List, ChainField)

  syntax KResult ::= Longrepr | JsonLongrepr
endmodule

module MINI-PYTEST-REPORT
  imports MINI-PYTEST-REPORT-SYNTAX
  imports INT
  imports BOOL
  imports LIST
  imports MAP

  configuration <k> $PGM:K </k>

  syntax JsonEntry ::= serializeEntry(Entry) [function]
  rule serializeEntry(reprEntry(T, D)) => jsonEntry(T, D)
  rule serializeEntry(nativeEntry(Lines)) => jsonNativeEntry(Lines)

  syntax Entry ::= deserializeEntry(JsonEntry) [function]
  rule deserializeEntry(jsonEntry(T, D)) => reprEntry(T, D)
  rule deserializeEntry(jsonNativeEntry(Lines)) => nativeEntry(Lines)

  syntax List ::= serializeEntries(List) [function]
  rule serializeEntries(.List) => .List
  rule serializeEntries(ListItem(E:Entry) REST:List)
    => ListItem(serializeEntry(E)) serializeEntries(REST)

  syntax List ::= deserializeEntries(List) [function]
  rule deserializeEntries(.List) => .List
  rule deserializeEntries(ListItem(E:JsonEntry) REST:List)
    => ListItem(deserializeEntry(E)) deserializeEntries(REST)

  syntax JsonTraceback ::= serializeTraceback(Traceback) [function]
  rule serializeTraceback(traceback(Entries, Extra, Style))
    => jsonTraceback(serializeEntries(Entries), Extra, Style)

  syntax Traceback ::= deserializeTraceback(JsonTraceback) [function]
  rule deserializeTraceback(jsonTraceback(Entries, Extra, Style))
    => traceback(deserializeEntries(Entries), Extra, Style)

  syntax JsonCrash ::= serializeCrash(Crash) [function]
  rule serializeCrash(noneCrash()) => jsonNoneCrash()
  rule serializeCrash(crash(Path, Line, Msg)) => jsonCrash(Path, Line, Msg)

  syntax Crash ::= deserializeCrash(JsonCrash) [function]
  rule deserializeCrash(jsonNoneCrash()) => noneCrash()
  rule deserializeCrash(jsonCrash(Path, Line, Msg)) => crash(Path, Line, Msg)

  syntax JsonChainElem ::= serializeChainElem(ChainElem) [function]
  rule serializeChainElem(chainElem(TB, CR, Desc))
    => jsonChainElem(serializeTraceback(TB), serializeCrash(CR), Desc)

  syntax ChainElem ::= deserializeChainElem(JsonChainElem) [function]
  rule deserializeChainElem(jsonChainElem(TB, CR, Desc))
    => chainElem(deserializeTraceback(TB), deserializeCrash(CR), Desc)

  syntax List ::= serializeChain(List) [function]
  rule serializeChain(.List) => .List
  rule serializeChain(ListItem(E:ChainElem) REST:List)
    => ListItem(serializeChainElem(E)) serializeChain(REST)

  syntax List ::= deserializeChain(List) [function]
  rule deserializeChain(.List) => .List
  rule deserializeChain(ListItem(E:JsonChainElem) REST:List)
    => ListItem(deserializeChainElem(E)) deserializeChain(REST)

  syntax Traceback ::= lastTraceback(List) [function]
  rule lastTraceback(ListItem(chainElem(TB, _, _))) => TB
  rule lastTraceback(ListItem(_) REST:List) => lastTraceback(REST)
    requires REST =/=K .List

  syntax Crash ::= lastCrash(List) [function]
  rule lastCrash(ListItem(chainElem(_, CR, _))) => CR
  rule lastCrash(ListItem(_) REST:List) => lastCrash(REST)
    requires REST =/=K .List

  syntax JsonLongrepr ::= serializeLongrepr(Longrepr) [function]
  rule serializeLongrepr(reprInfo(TB, CR, Sections))
    => jsonLongrepr(serializeTraceback(TB), serializeCrash(CR), Sections, noChain())
  rule serializeLongrepr(chainRepr(ListItem(E), Sections))
    => jsonLongrepr(
         serializeTraceback(lastTraceback(ListItem(E))),
         serializeCrash(lastCrash(ListItem(E))),
         Sections,
         noChain())
  rule serializeLongrepr(chainRepr(ListItem(E1) ListItem(E2) REST, Sections))
    => jsonLongrepr(
         serializeTraceback(lastTraceback(ListItem(E1) ListItem(E2) REST)),
         serializeCrash(lastCrash(ListItem(E1) ListItem(E2) REST)),
         Sections,
         someChain(serializeChain(ListItem(E1) ListItem(E2) REST)))

  syntax Longrepr ::= deserializeLongrepr(JsonLongrepr) [function]
  rule deserializeLongrepr(jsonLongrepr(TB, CR, Sections, noChain()))
    => reprInfo(deserializeTraceback(TB), deserializeCrash(CR), Sections)
  rule deserializeLongrepr(jsonLongrepr(_, _, Sections, someChain(Chain)))
    => chainRepr(deserializeChain(Chain), Sections)
endmodule
