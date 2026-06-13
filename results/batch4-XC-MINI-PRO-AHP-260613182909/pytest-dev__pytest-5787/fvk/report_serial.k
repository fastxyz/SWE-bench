// =============================================================================
// report_serial.k  —  mini-X K fragment semantics for the pytest-5787 fix
// =============================================================================
// Target: BaseReport._to_json (serialize_longrepr) and BaseReport._from_json in
// repo/src/_pytest/reports.py, as patched by V1.
//
// This is a FUNCTIONAL/STRUCTURAL fragment: the code is pure (de)serialization of
// an algebraic value — no store, no heap, no arithmetic.  We model exactly the
// two things the fix turns on:
//   (1) the BRANCHING of _to_json/_from_json over the four longrepr shapes and
//       the chain-vs-None decision, and
//   (2) the LIST ITERATION (the `[... for x in ...]` comprehensions over
//       reprentries and over chain), which becomes structural recursion here.
//
// Leaf payloads the code copies verbatim (lines, paths, messages, styles,
// extraline, sections) are abstracted as opaque Int tokens that round-trip
// unchanged — faithful, because the fix never inspects them.  See SPEC.md
// "Modeling assumptions / trusted base" for why this abstraction is sound
// (tuple<->list transport, ReprTracebackNative<->ReprTraceback, opaque leaves).
//
// Python `raise _report_unserialization_failure(...)` (a RuntimeError) is NOT
// modeled as an exception (out of fragment, per formalize.md).  Instead the
// deserialiser is PARTIAL: it is simply undefined on an Unknown entry kind.
// "Undefined on the malformed input" is the matching-logic model of the guard;
// the guard itself becomes Finding F1/F8.  Everything else is total.
// =============================================================================

module REPORT-SERIAL-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  // ----- in-memory (runtime) longrepr objects ------------------------------
  // Kind = the serialized entry "type" tag.  ReprEntry/ReprEntryNative are the
  // two kinds _from_json knows; Unknown stands for any other tag (the corruption
  // that test_unserialization_failure injects).
  syntax Kind     ::= "ReprEntry" | "ReprEntryNative" | "Unknown"
  syntax Entry    ::= mkE(Kind, Int)                  // (type, opaque entry data)
  syntax Entries  ::= ".Es"        [klabel(nilE)]     // cons-list of entries
                    | Entry ":" Entries  [klabel(consE)]

  syntax Tb       ::= mkTb(Entries, Int)              // ReprTraceback(reprentries, opaque extraline+style)
  syntax Crash    ::= "noCrash" | mkCrash(Int)        // ReprFileLocation | None
  syntax Descr    ::= "noDescr" | mkDescr(Int)        // chain-link description | None

  syntax Link     ::= mkLink(Tb, Crash, Descr)        // one chain element (tb, crash, descr)
  syntax Links    ::= ".Ls"        [klabel(nilL)]     // cons-list; HEAD = innermost exception,
                    | Link ";" Links [klabel(consL)]  // LAST = outermost == Python chain[-1]

  // the four shapes _to_json branches on (see serialize_longrepr + the guard
  // `hasattr(longrepr,'reprtraceback') and hasattr(longrepr,'reprcrash')`):
  syntax LongRepr ::= "lrNone"                        // report.longrepr is None
                    | lrStr(Int)                      // longrepr w/o reprtraceback  -> str(longrepr)
                    | single(Tb, Crash, Int)          // ReprExceptionInfo (e.g. --tb=native); Int = sections
                    | chained(Links, Int)             // ExceptionChainRepr (default tb styles)

  // ----- serialized (wire / JSON-able) values ------------------------------
  syntax JEntry   ::= jE(Kind, Int)
  syntax JEntries ::= ".JEs" [klabel(jnilE)] | JEntry ":" JEntries [klabel(jconsE)]
  syntax JTb      ::= jTb(JEntries, Int)
  syntax JCrash   ::= "jNoCrash" | jCrash(Int)
  syntax JDescr   ::= "jNoDescr" | jDescr(Int)
  syntax JLink    ::= jLink(JTb, JCrash, JDescr)
  syntax JLinks   ::= ".JLs" [klabel(jnilL)] | JLink ";" JLinks [klabel(jconsL)]
  // d["longrepr"]["chain"] is either Python None (jChainNull) or a (JSON) list:
  syntax JChain   ::= "jChainNull" | jChain(JLinks)
  syntax J        ::= "jNull" | jStr(Int) | jObj(JTb, JCrash, Int, JChain)

  syntax KResult  ::= LongRepr | Tb | Entries | Entry | Crash | Descr | Links
                    | J | JTb | JEntries | JEntry | JCrash | JDescr | JChain | JLinks
endmodule

module REPORT-SERIAL
  imports REPORT-SERIAL-SYNTAX
  imports INT
  imports BOOL

  // =========================================================================
  // serialize_longrepr  (BaseReport._to_json)  — TOTAL
  // =========================================================================
  syntax J        ::= serLR(LongRepr)  [function, total]
  syntax JTb      ::= serTb(Tb)        [function, total]
  syntax JEntries ::= serEs(Entries)   [function, total]
  syntax JEntry   ::= serE(Entry)      [function, total]
  syntax JCrash   ::= serC(Crash)      [function, total]
  syntax JDescr   ::= serD(Descr)      [function, total]
  syntax JLinks   ::= serLs(Links)     [function, total]

  rule serLR(lrNone)            => jNull
  rule serLR(lrStr(S))          => jStr(S)
  // ReprExceptionInfo: chain serialized as None
  rule serLR(single(TB, C, SE)) => jObj(serTb(TB), serC(C), SE, jChainNull)
  // ExceptionChainRepr: top-level reprtraceback/reprcrash are the OUTERMOST
  // (chain[-1]) AND the full chain is serialized.
  rule serLR(chained(LS, SE))   => jObj(serTb(tbOfLast(LS)), serC(crashOfLast(LS)), SE, jChain(serLs(LS)))

  rule serTb(mkTb(ES, X))          => jTb(serEs(ES), X)
  rule serEs(.Es)                  => .JEs
  rule serEs(E : ES)               => serE(E) : serEs(ES)
  rule serE(mkE(K, D))             => jE(K, D)             // type + data copied verbatim (no validation)
  rule serC(noCrash)               => jNoCrash             // serialize_repr_crash tolerates None
  rule serC(mkCrash(L))            => jCrash(L)
  rule serD(noDescr)               => jNoDescr
  rule serD(mkDescr(D))            => jDescr(D)
  rule serLs(.Ls)                  => .JLs
  rule serLs(mkLink(TB,C,D) ; LS)  => jLink(serTb(TB), serC(C), serD(D)) ; serLs(LS)

  // chain[-1] = outermost (Python ExceptionChainRepr.reprtraceback/reprcrash)
  syntax Tb    ::= tbOfLast(Links)    [function]
  syntax Crash ::= crashOfLast(Links) [function]
  rule tbOfLast(mkLink(TB,_,_) ; .Ls)   => TB
  rule tbOfLast(_ ; (L:Link ; LS))      => tbOfLast(L ; LS)
  rule crashOfLast(mkLink(_,C,_) ; .Ls) => C
  rule crashOfLast(_ ; (L:Link ; LS))   => crashOfLast(L ; LS)
  // (deliberately NO rule for tbOfLast(.Ls)/crashOfLast(.Ls): an ExceptionChainRepr
  //  always has chain != [] — Python ExceptionChainRepr.__init__ does chain[-1].)

  // =========================================================================
  // deserialize  (BaseReport._from_json)  — PARTIAL (undefined on Unknown kind)
  // =========================================================================
  syntax LongRepr ::= deLR(J)        [function]
  syntax Tb       ::= deTb(JTb)      [function]
  syntax Entries  ::= deEs(JEntries) [function]
  syntax Entry    ::= deE(JEntry)    [function]   // undefined on jE(Unknown,_)
  syntax Crash    ::= deC(JCrash)    [function, total]
  syntax Descr    ::= deD(JDescr)    [function, total]
  syntax Links    ::= deLs(JLinks)   [function]

  rule deLR(jNull)   => lrNone
  rule deLR(jStr(S)) => lrStr(S)
  // _from_json ALWAYS deserialises the top-level traceback first (validation),
  // THEN branches on chain.  "Process both" is captured by requiring the
  // top-level tb to be all-known in BOTH jObj rules:
  rule deLR(jObj(JT, JC, SE, jChainNull))   => single(deTb(JT), deC(JC), SE)
       requires allKnownJTb(JT)
  rule deLR(jObj(JT, _JC, SE, jChain(JLS))) => chained(deLs(JLS), SE)
       requires allKnownJTb(JT) andBool allKnownJLs(JLS)
  // When allKnownJTb(JT) is false, OR (in the chain case) allKnownJLs(JLS) is
  // false, NO rule matches => deLR is undefined here.  That undefinedness is the
  // model of `_report_unserialization_failure` raising RuntimeError (Finding F1).

  rule deTb(jTb(JES, X))           => mkTb(deEs(JES), X)
  rule deEs(.JEs)                  => .Es
  rule deEs(JE : JES)              => deE(JE) : deEs(JES)
  rule deE(jE(ReprEntry, D))       => mkE(ReprEntry, D)
  rule deE(jE(ReprEntryNative, D)) => mkE(ReprEntryNative, D)
  // NO rule for deE(jE(Unknown,_))  => undefined (RuntimeError).
  rule deC(jNoCrash)               => noCrash             // deserialize_repr_crash handles None
  rule deC(jCrash(L))              => mkCrash(L)
  rule deD(jNoDescr)               => noDescr
  rule deD(jDescr(D))              => mkDescr(D)
  rule deLs(.JLs)                  => .Ls
  rule deLs(jLink(JT,JC,JD) ; JLS) => mkLink(deTb(JT), deC(JC), deD(JD)) ; deLs(JLS)

  // =========================================================================
  // "all entry kinds are known" — the in-domain predicate (no Unknown tag).
  // Distributes structurally over the cons-lists (no induction needed to define).
  // =========================================================================
  syntax Bool ::= allKnownEs(Entries)    [function, total]
                | allKnownTb(Tb)         [function, total]
                | allKnownLs(Links)      [function, total]
                | allKnownJEs(JEntries)  [function, total]
                | allKnownJTb(JTb)       [function, total]
                | allKnownJLs(JLinks)    [function, total]
                | isKnown(Kind)          [function, total]
  rule isKnown(ReprEntry)       => true
  rule isKnown(ReprEntryNative) => true
  rule isKnown(Unknown)         => false

  rule allKnownEs(.Es)            => true
  rule allKnownEs(mkE(K,_) : ES) => isKnown(K) andBool allKnownEs(ES)
  rule allKnownTb(mkTb(ES,_))     => allKnownEs(ES)
  rule allKnownLs(.Ls)            => true
  rule allKnownLs(mkLink(TB,_,_) ; LS) => allKnownTb(TB) andBool allKnownLs(LS)

  rule allKnownJEs(.JEs)            => true
  rule allKnownJEs(jE(K,_) : JES)  => isKnown(K) andBool allKnownJEs(JES)
  rule allKnownJTb(jTb(JES,_))      => allKnownJEs(JES)
  rule allKnownJLs(.JLs)            => true
  rule allKnownJLs(jLink(JT,_,_) ; JLS) => allKnownJTb(JT) andBool allKnownJLs(JLS)
endmodule
