requires "mini-staticfiles.k"

module STATICFILES-SPEC
  imports MINI-STATICFILES

  // SPEC-PROVENANCE:
  // - from_prompt: "max_post_process_passes = 0" => zero is an in-domain pass count.
  // - from_prompt: "UnboundLocalError: local variable 'substitutions' referenced before assignment" => final branch must read a bound value.
  // - from_code: V1 initializes substitutions to False before the repeated-pass loop.
  claim <k> postProcessTail(0, BS:Bools) => ok(false) ... </k>
    [label(V1_ZERO_PASS)]

  // SPEC-PROVENANCE:
  // - from_prompt: "subtitutions is only set if the loop is entered at least once" => pre-V1 zero passes reproduce the reported symptom.
  claim <k> legacyPostProcessTail(0, BS:Bools) => unboundLocal ... </k>
    [label(LEGACY_ZERO_PASS_REPRODUCES_BUG)]

  // SPEC-PROVENANCE:
  // - from_code: on positive pass counts, the first statement in the loop remains substitutions = False.
  // - from_spec: positive-pass behavior must be preserved.
  claim <k> postProcessTail(P:Int, BS:Bools) => resultForFinal(finalSubstitutions(P, BS)) ... </k>
    requires P >Int 0
    [label(V1_POSITIVE_PASS)]

  // SPEC-PROVENANCE:
  // - from_code: pre-V1 behavior was defined when the repeated-pass loop executed at least once.
  // - from_spec: V1 should match that defined positive-pass behavior.
  claim <k> legacyPostProcessTail(P:Int, BS:Bools) => resultForFinal(finalSubstitutions(P, BS)) ... </k>
    requires P >Int 0
    [label(LEGACY_POSITIVE_PASS)]

  // SPEC-PROVENANCE:
  // - from_code: the max-exceeded result is controlled solely by the final value of substitutions.
  // - from_spec: zero passes must not yield maxExceeded; positive passes yield it only when Final(P, BS) is true.
  claim <k> postProcessTail(P:Int, BS:Bools) => maxExceeded ... </k>
    requires P >Int 0
     andBool finalSubstitutions(P, BS) ==Bool true
    [label(V1_MAX_EXCEEDED)]
endmodule
