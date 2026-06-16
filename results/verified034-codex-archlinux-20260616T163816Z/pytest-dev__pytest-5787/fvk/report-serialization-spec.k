requires "mini-pytest-report.k"

module REPORT-SERIALIZATION-SPEC
  imports MINI-PYTEST-REPORT
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - E-001/E-002/E-006: chained reports must preserve every traceback,
  //   crash location, description, and their order.
  // CLAIM: MULTI-CHAIN-ROUNDTRIP
  claim
    <k>
      deserializeLongrepr(
        serializeLongrepr(chainRepr(ListItem(E1:ChainElem) ListItem(E2:ChainElem) REST:List, Sections:List))
      )
      => chainRepr(ListItem(E1) ListItem(E2) REST, Sections)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-007/E-008: ordinary single-exception reports should retain the
  //   historical no-chain serialized shape.
  // CLAIM: SINGLE-CHAIN-COMPAT
  claim
    <k>
      deserializeLongrepr(
        serializeLongrepr(chainRepr(ListItem(chainElem(TB:Traceback, CR:Crash, Desc:String)), Sections:List))
      )
      => reprInfo(TB, CR, Sections)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-007: non-chain structured longreprs preserve top-level
  //   traceback/crash/sections.
  // CLAIM: REPRINFO-ROUNDTRIP
  claim
    <k>
      deserializeLongrepr(serializeLongrepr(reprInfo(TB:Traceback, CR:Crash, Sections:List)))
      => reprInfo(TB, CR, Sections)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-007: traceback entry data and order are preserved.
  // CLAIM: TRACEBACK-ROUNDTRIP
  claim
    <k>
      deserializeTraceback(serializeTraceback(traceback(Entries:List, Extra:String, Style:String)))
      => traceback(Entries, Extra, Style)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-007: supported entry tags round-trip.
  // CLAIM: ENTRY-ROUNDTRIP
  claim
    <k> deserializeEntry(serializeEntry(reprEntry(T:String, D:Map))) => reprEntry(T, D) </k>
    [all-path]

  // CLAIM: NATIVE-ENTRY-ROUNDTRIP
  claim
    <k> deserializeEntry(serializeEntry(nativeEntry(Lines:List))) => nativeEntry(Lines) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-007: crash location data and missing crash locations are preserved.
  // CLAIM: CRASH-ROUNDTRIP
  claim
    <k> deserializeCrash(serializeCrash(crash(Path:String, Line:Int, Msg:String))) => crash(Path, Line, Msg) </k>
    [all-path]

  // CLAIM: CRASH-NONE-ROUNDTRIP
  claim
    <k> deserializeCrash(serializeCrash(noneCrash())) => noneCrash() </k>
    [all-path]
endmodule
