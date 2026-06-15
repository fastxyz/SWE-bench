requires "mini-python-regex.k"

module USERNAME-VALIDATOR-SPEC
  imports MINI-PYTHON-REGEX
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - E-001/E-005: ASCII validator allows ASCII letters/numbers/underscore
  //   plus dot, at, plus, and hyphen.
  // - E-007: RegexValidator uses search(), so anchors must force the whole
  //   string to match.
  claim
    <k> validate(asciiUsername, CS:Chars) => valid </k>
    requires CS =/=K .Chars andBool allAllowed(asciiUsername, CS)
    [label(ASCII_ACCEPT), all-path]

  // SPEC-PROVENANCE:
  // - E-001/E-002/E-005: Any character outside the allowed set, including
  //   newline, must be rejected; empty input is rejected by '+'.
  claim
    <k> validate(asciiUsername, CS:Chars) => invalid </k>
    requires notBool (CS =/=K .Chars andBool allAllowed(asciiUsername, CS))
    [label(ASCII_REJECT), all-path]

  // SPEC-PROVENANCE:
  // - E-002/E-003: A final LF was the reported bug; \A...\Z rejects it.
  claim
    <k> validate(asciiUsername, appendLF(CS:Chars)) => invalid </k>
    requires CS =/=K .Chars andBool allAllowed(asciiUsername, CS)
    [label(ASCII_REJECT_TRAILING_LF), all-path]

  // SPEC-PROVENANCE:
  // - E-001/E-006: Unicode validator allows Unicode word characters plus
  //   dot, at, plus, and hyphen.
  // - E-007: RegexValidator uses search(), so anchors must force the whole
  //   string to match.
  claim
    <k> validate(unicodeUsername, CS:Chars) => valid </k>
    requires CS =/=K .Chars andBool allAllowed(unicodeUsername, CS)
    [label(UNICODE_ACCEPT), all-path]

  // SPEC-PROVENANCE:
  // - E-001/E-002/E-006: Any character outside the allowed set, including
  //   newline, must be rejected; empty input is rejected by '+'.
  claim
    <k> validate(unicodeUsername, CS:Chars) => invalid </k>
    requires notBool (CS =/=K .Chars andBool allAllowed(unicodeUsername, CS))
    [label(UNICODE_REJECT), all-path]

  // SPEC-PROVENANCE:
  // - E-002/E-003: A final LF was the reported bug; \A...\Z rejects it.
  claim
    <k> validate(unicodeUsername, appendLF(CS:Chars)) => invalid </k>
    requires CS =/=K .Chars andBool allAllowed(unicodeUsername, CS)
    [label(UNICODE_REJECT_TRAILING_LF), all-path]
endmodule
