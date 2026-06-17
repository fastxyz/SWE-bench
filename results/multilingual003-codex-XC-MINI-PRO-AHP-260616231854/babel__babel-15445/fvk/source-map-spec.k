requires "mini-ts-sourcemap.k"

module SOURCE-MAP-COPY-SPEC
  imports MINI-TS-SOURCEMAP
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: "generating source maps fails due to `sourcesContent` being undefined"
  //   => absent source contents must not be indexed and must not throw.
  // - from_prompt: inputSourceMap includes sources/mappings/names with no sourcesContent
  //   => noContent is an in-domain input.
  // - from_code: V1 checks `if (sourcesContent)` before the loop.
  // CLAIM: COPY-NO-CONTENT
  claim
    <k> copyInput(SOURCES:List, noContent) => .K ... </k>
    <contents> M:Map => M </contents>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: pre-existing behavior called setSourceContent pairwise for input maps.
  // - from_intent: preserve valid maps that include sourcesContent.
  // - from_code: V1 guards each indexed read with `i < sourcesContent.length`.
  // CLAIM: COPY-SOME-CONTENT
  claim
    <k> copyInput(SOURCES:List, someContent(CONTENTS:List)) => .K ... </k>
    <contents> M:Map => copyPairs(M, SOURCES, CONTENTS) </contents>
    [all-path]
endmodule
