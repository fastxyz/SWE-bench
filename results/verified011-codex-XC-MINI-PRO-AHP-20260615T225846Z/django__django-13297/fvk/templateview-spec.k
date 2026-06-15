requires "mini-templateview.k"

module TEMPLATEVIEW-SPEC
  imports MINI-TEMPLATEVIEW
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - E1/E2/E3: get_context_data() must receive raw URL kwargs.
  // - Code fact: V1 calls get_context_data(**kwargs) before the wrapper helper.
  claim [GET-FORWARDS-RAW-KWARGS]:
    <k> get(KW:Map, C:Map) => .K ... </k>
    <seenKwargs> .Map => KW </seenKwargs>
    <response> .Map => wrapCtx(C, KW) </response>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E6/E8: final context access remains supported with deprecation.
  // - Code fact: V1 wraps the returned context before render_to_response().
  claim [GET-RENDERS-WRAPPED-CONTEXT]:
    <k> get(KW:Map, C:Map) => .K ... </k>
    <response> .Map => wrapCtx(C, KW) </response>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E6/E8: unchanged final context URL kwargs keep delayed warning.
  claim [WRAP-UNCHANGED-ENTRY]:
    <k> get((K:Id |-> V:Val), (K |-> V)) => .K ... </k>
    <seenKwargs> .Map => (K |-> V) </seenKwargs>
    <response> .Map => (K |-> lazy(K, V)) </response>
    [all-path]

  // SPEC-PROVENANCE:
  // - I5: override/extra_context replacements must not be overwritten.
  claim [DO-NOT-WRAP-REMOVED-OR-REPLACED]:
    <k> get((K:Id |-> V:Val), (K |-> V2:Val)) => .K ... </k>
    <seenKwargs> .Map => (K |-> V) </seenKwargs>
    <response> .Map => (K |-> V2) </response>
    requires notBool (V ==K V2)
    [all-path]

  // SPEC-PROVENANCE:
  // - I5 and F3: removed entries stay removed.
  claim [DO-NOT-REINTRODUCE-MISSING]:
    <k> get((K:Id |-> V:Val), .Map) => .K ... </k>
    <seenKwargs> .Map => (K |-> V) </seenKwargs>
    <response> .Map => .Map </response>
    [all-path]
endmodule
