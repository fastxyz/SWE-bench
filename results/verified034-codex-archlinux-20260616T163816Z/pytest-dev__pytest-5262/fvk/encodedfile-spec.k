requires "mini-capture.k"

module ENCODEDFILE-SPEC
  imports MINI-CAPTURE

  // SPEC-PROVENANCE:
  // - from_prompt: "_pytest.capture.EncodedFile mode should not include `b`"
  //   => wrapper mode contains no binary flag.
  // - from_prompt: "incorrectly advertises `rb+`, the mode of the underlying
  //   stream" => wrapper mode is derived from, but not equal to, buffer mode
  //   when the buffer mode contains b.
  // - from_prompt_hint: "return self.buffer.mode.replace('b', '')"
  //   => remove all binary flags and preserve non-binary flags.
  claim <k> encodedFileMode(M:Mode) => stripB(M) </k>
        <bufferMode> M </bufferMode>

  // SPEC-PROVENANCE:
  // - from_prompt: third-party code chooses bytes when it sees b in out.mode.
  //   => after the fix, out.mode must not contain b.
  claim hasB(stripB(M:Mode)) => false

  // SPEC-PROVENANCE:
  // - from_prompt_hint: replace("b", "") removes only the b characters.
  //   => non-binary mode flags are preserved by stripB.
  // This preservation lemma is discharged structurally in PROOF.md.
  claim stripB(mcR M:Mode) => mcR stripB(M)
  claim stripB(mcW M:Mode) => mcW stripB(M)
  claim stripB(mcA M:Mode) => mcA stripB(M)
  claim stripB(mcPlus M:Mode) => mcPlus stripB(M)
  claim stripB(mcT M:Mode) => mcT stripB(M)
  claim stripB(mcU M:Mode) => mcU stripB(M)
  claim stripB(mcOther M:Mode) => mcOther stripB(M)

  // SPEC-PROVENANCE:
  // - from_prompt: the bug is the wrapper advertising the underlying stream
  //   mode; callers can still inspect the underlying stream via .buffer.
  claim <k> encodedFileBufferMode(M:Mode) => M </k>
        <bufferMode> M </bufferMode>
endmodule
