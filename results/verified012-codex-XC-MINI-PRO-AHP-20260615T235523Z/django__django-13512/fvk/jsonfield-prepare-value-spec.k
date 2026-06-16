requires "mini-json-form.k"

module JSONFIELD-PREPARE-VALUE-SPEC
  imports MINI-JSON-FORM

  // SPEC-PROVENANCE:
  // - from_code: InvalidJSONInput branch returns value unchanged.
  // - from_public_compatibility: redisplay invalid submitted JSON without overquoting.
  claim [CLAIM-PREPARE-INVALID]:
    <k> prepareValue(invalidInput(S:String), E:Encoder) => raw(S) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "Admin doesn't display properly unicode chars in JSONFields."
  // - from_prompt: default json.dumps displays China text as "\u4e2d\u56fd".
  // - semantic obligation: use the display serialization path that preserves Unicode.
  claim [CLAIM-PREPARE-UNICODE-CHINA]:
    <k> prepareValue(jstring(chinaText), E:Encoder) => displayUnicodeChina </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: non-ASCII characters in JSONField values should display readably.
  // - from_code: normal branch calls json.dumps with cls=self.encoder.
  // - semantic obligation: every non-invalid value is serialized with ensure_ascii=False
  //   while preserving the symbolic encoder argument E.
  claim [CLAIM-PREPARE-GENERAL]:
    <k> prepareValue(V:JVal, E:Encoder) => jsonDumps(V, false, E) </k>
    requires notBool isInvalid(V)
    [all-path]
endmodule
