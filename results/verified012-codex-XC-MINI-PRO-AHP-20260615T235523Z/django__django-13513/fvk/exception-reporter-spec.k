requires "mini-exception-chain.k"

module EXCEPTION-REPORTER-SPEC
  imports MINI-EXCEPTION-CHAIN
  imports K-EQUAL
  imports MAP-SYMBOLIC

  // SPEC-PROVENANCE:
  // - from_prompt: "raise ValueError('my new error') from None" and "the debug error view still shows the RuntimeError" =>
  //   when explicit cause is none and suppress-context is true, the resolver must return none.
  claim
    <k> resolve(none, true, OLD:Cause) => none ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "explicit_or_implicit_cause" and proposed PEP 415 shape =>
  //   an explicit cause has precedence over suppress-context and implicit context.
  claim
    <k> resolve(CAUSE:Cause, SUPPRESS:Bool, CTX:Cause) => CAUSE ... </k>
    requires CAUSE =/=K none
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "explicit or implicit cause" and PEP 415 context semantics =>
  //   implicit context is used only when no explicit cause exists and context is not suppressed.
  claim
    <k> resolve(none, false, CTX:Cause) => CTX ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: frame dictionaries expose exc_cause_explicit to templates as an explicit-cause branch flag.
  // - from_intent: the direct-cause message must be selected by explicit cause existence, not object truthiness.
  claim
    <k> isExplicit(none) => false ... </k>
    [all-path]

  claim
    <k> isExplicit(CAUSE:Cause) => true ... </k>
    requires CAUSE =/=K none
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: example ValueError has context RuntimeError but was raised "from None" =>
  //   collecting the visible chain from the ValueError records the ValueError only.
  // - from_code: collect models the get_traceback_frames exception-chain loop, abstracting away source-line rendering.
  claim
    <k> collect(exc(1), 2) => .K ... </k>
    <explicit> exc(1) |-> none </explicit>
    <suppress> exc(1) |-> true </suppress>
    <context> exc(1) |-> exc(0) </context>
    <seen> .List => ListItem(exc(1)) </seen>
    [all-path]

  // SPEC-PROVENANCE:
  // - discriminator for the abstraction: if suppress-context is false, the same context is visible.
  claim
    <k> collect(exc(1), 3) => .K ... </k>
    <explicit> exc(1) |-> none exc(0) |-> none </explicit>
    <suppress> exc(1) |-> false exc(0) |-> false </suppress>
    <context> exc(1) |-> exc(0) exc(0) |-> none </context>
    <seen> .List => ListItem(exc(1)) ListItem(exc(0)) </seen>
    [all-path]
endmodule
