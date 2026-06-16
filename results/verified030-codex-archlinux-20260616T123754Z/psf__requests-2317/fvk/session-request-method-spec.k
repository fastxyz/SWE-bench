requires "mini-requests-method.k"

module SESSION-REQUEST-METHOD-SPEC
  imports MINI-REQUESTS-METHOD

  // SPEC-PROVENANCE:
  // - from_prompt: "Seems if requests handled the method value being a binary
  //   string, we wouldn't have any problem." => byte-string HTTP methods in
  //   Session.request must normalize to native HTTP method text.
  // - from_prompt: "`builtin_str(method)` converts method from b'GET' to
  //   \"b'GET'\"" => the bytes repr text is the defect, not a valid output.
  // - from_hint: "replaced with `to_native_str`" => use the native-string
  //   conversion path rather than Python 3 str(bytes).
  // - from_default_domain: HTTP method tokens are ASCII.
  // - from_code: V1 calls to_native_string(method), then upper(), then prepares
  //   the Request.
  claim
    <k> sessionRequest(bytes(T:Token))
      => prepared(upperToken(T))
    </k>
    requires asciiHttpToken(T)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: "method for the new Request object" plus existing behavior =>
  //   native string methods are still accepted and uppercased.
  // - from_code: to_native_string is identity for builtin native strings.
  claim
    <k> sessionRequest(native(T:Token))
      => prepared(upperToken(T))
    </k>
    requires asciiHttpToken(T)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: pre-V1 behavior using builtin_str(bytes) is the reported
  //   defect. This legacy claim is included only as a discriminator showing
  //   what the V1 code no longer does.
  claim
    <k> legacySessionRequest(bytes(T:Token))
      => preparedBytesRepr(upperToken(T))
    </k>
    requires asciiHttpToken(T)
    [all-path]
endmodule
