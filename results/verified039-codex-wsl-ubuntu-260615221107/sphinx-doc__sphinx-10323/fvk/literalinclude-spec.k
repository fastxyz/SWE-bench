requires "mini-literalinclude.k"

module LITERALINCLUDE-SPEC
  imports MINI-LITERALINCLUDE

  // SPEC-PROVENANCE:
  // - from_prompt: "dedent was applied only to the literalinclude and not to
  //   the prepend and append content" => dedent must precede prepend/append.
  // - from_code: LiteralIncludeReader.read() is a sequential filter pipeline.
  claim [read-pipeline]:
    <k> read(F:Lines, selector, D:DedentOpt, P:String, HP:Bool, A:String, HA:Bool)
      => append(prepend(dedent(select(F, selector), D), P, HP), A, HA)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: warning-free workaround fails because non-file option text
  //   is stripped by dedent.
  // - from_intent: dedent warning source is selected include-file content only.
  claim [dedent-warning-scope]:
    <k> dedentWarns(select(F:Lines, selector), D:DedentOpt)
      => dedentWarns(select(F, selector), D)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: prepend/append without dedent yields prepend, selected
  //   line, append.
  claim [no-dedent-frame]:
    <k> read(F:Lines, selector, noDedent, P:String, HP:Bool, A:String, HA:Bool)
      => append(prepend(select(F, selector), P, HP), A, HA)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: diff branch bypasses the normal filter list.
  // - from_intent: V1 must not change diff behavior.
  claim [diff-frame]:
    <k> diffRead(F:Lines) => F </k>
    [all-path]
endmodule
