// K-style claims for pytest fd capture newline preservation.
// Constructed, not machine-checked in this environment.

requires "mini-capture.k"

module CAPTURE-SPEC
  imports MINI-CAPTURE

  // SPEC-PROVENANCE:
  // - from_prompt: "capfd.readouterr() converts \r to \n" is reported as a
  //   regression, and the reproducer asserts out.endswith("\r").
  // - from_docs: capfd returns text objects from fd-level capture.
  // - from_code: FDCapture.snap reads self.tmpfile.read() and V1 constructs
  //   that tmpfile with newline="".
  claim <k> snapText => .K </k>
        <tmp> bytes("Greetings from DOS\r") => .Bytes </tmp>
        <newline> Preserve </newline>
        <textResult> _ => "Greetings from DOS\r" </textResult>
        <bytesResult> BR => BR </bytesResult>
        [label(CAPFD-PRESERVES-CR), all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: borgbackup expected stderr "  0%\r".
  // - from_code: the same FDCapture class is used for fd 1 and fd 2.
  claim <k> snapText => .K </k>
        <tmp> bytes("  0%\r") => .Bytes </tmp>
        <newline> Preserve </newline>
        <textResult> _ => "  0%\r" </textResult>
        <bytesResult> BR => BR </bytesResult>
        [label(CAPFD-PRESERVES-STDERR-CR), all-path]

  // SPEC-PROVENANCE:
  // - from_docs: capfdbinary returns bytes from fd-level capture.
  // - from_public_tests: capfdbinary should return undecodable bytes unchanged.
  // - from_code: FDCaptureBinary.snap reads self.tmpfile.buffer.read(), not
  //   self.tmpfile.read(), so text newline translation is not involved.
  claim <k> snapBytes => .K </k>
        <tmp> bytes("\xfe\x98 ") => .Bytes </tmp>
        <newline> Preserve </newline>
        <textResult> TR => TR </textResult>
        <bytesResult> _ => bytes("\xfe\x98 ") </bytesResult>
        [label(CAPFDBINARY-PRESERVES-BYTES), all-path]
endmodule
