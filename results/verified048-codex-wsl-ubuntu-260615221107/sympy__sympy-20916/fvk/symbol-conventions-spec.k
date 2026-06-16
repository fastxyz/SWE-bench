requires "mini-symbol-conventions.k"

module SYMBOL-CONVENTIONS-SPEC
  imports MINI-SYMBOL-CONVENTIONS

  // SPEC-PROVENANCE:
  // - from_prompt: "pprint unicode does not format subscripts on Greek letters"
  //   => Unicode Greek letter bases with trailing ASCII digits must split.
  // - from_prompt_hint: "[a-zA-Z] ... should be using \w"
  //   => The base class must admit Unicode word characters.
  // - from_public_tests: ASCII suffixes such as beta12/q21
  //   => Multi-digit suffixes remain a single subscript run.
  claim
    <k> applyNameWithDigits(concat(B:Name, D:Name)) => Split(B, D) </k>
    requires isBaseRun(B) andBool isAsciiDigitRun(D)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: explicit underscore/caret cases
  //   => The implicit matcher must not consume underscore as part of the base.
  // - from_code: V1 base class is \w minus \d minus "_".
  claim
    <k> applyNameWithDigits(N:Name) => NoSplit(N) </k>
    requires notBool isNameDigits(N)
    [all-path]
endmodule
