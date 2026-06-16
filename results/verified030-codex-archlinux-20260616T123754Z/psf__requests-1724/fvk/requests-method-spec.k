requires "mini-python-requests-method.k"

module REQUESTS-METHOD-SPEC
  imports MINI-PYTHON-REQUESTS-METHOD

  // SPEC-PROVENANCE:
  // - from_prompt: "method=u'POST' ... produces a UnicodeDecodeError" => bug.
  // - from_prompt: "when it should be a string" => Python 2 native string.
  // - from_code: V1 calls to_native_string(self.method.upper()).
  claim <k> prepareMethod(Py2, Unicode(S)) => Native(upperAscii(S)) </k>
    requires asciiMethod(S)
    [label(PREPARE-METHOD-PY2-UNICODE)]

  // SPEC-PROVENANCE:
  // - from_prompt: method='POST' already works => preserve native-string path.
  // - from_code: native strings pass through to_native_string unchanged.
  claim <k> prepareMethod(Py2, Native(S)) => Native(upperAscii(S)) </k>
    requires asciiMethod(S)
    [label(PREPARE-METHOD-PY2-NATIVE)]

  // SPEC-PROVENANCE:
  // - from_prompt traceback: requests.request -> Session.request ->
  //   adapter.send => public failing construction path.
  // - from_default_domain: ASCII uppercasing is idempotent.
  claim <k> sessionRequestMethod(Py2, Unicode(S)) => Native(upperAscii(S)) </k>
    requires asciiMethod(S)
    [label(SESSION-REQUEST-PY2-UNICODE)]

  // SPEC-PROVENANCE:
  // - from_code: prepare_method only normalizes when method is not None.
  // - frame condition: V1 does not change the None branch.
  claim <k> prepareMethod(PY, None) => None </k>
    [label(PREPARE-METHOD-NONE)]
endmodule

