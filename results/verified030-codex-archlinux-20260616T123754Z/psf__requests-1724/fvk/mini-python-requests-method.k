requires "domains.md"

module MINI-PYTHON-REQUESTS-METHOD-SYNTAX
  imports STRING
  imports BOOL

  syntax PyVer ::= Py2 | Py3
  syntax PyObj ::= None
                 | Native(String)
                 | Unicode(String)
                 | Bytes3(String)

  syntax PyObj ::= upper(PyObj) [function]
                 | toNative(PyVer, PyObj) [function]
                 | prepareMethod(PyVer, PyObj) [function]
                 | sessionPrepareRequestMethod(PyVer, PyObj) [function]
                 | sessionRequestMethod(PyVer, PyObj) [function]

  syntax String ::= upperAscii(String) [function]
  syntax Bool ::= asciiMethod(String) [function]
endmodule

module MINI-PYTHON-REQUESTS-METHOD
  imports MINI-PYTHON-REQUESTS-METHOD-SYNTAX

  configuration <k> $PGM:PyObj </k>

  // Method uppercasing preserves the object family, matching Python 2's
  // behavior where unicode.upper() returns unicode and str.upper() returns str.
  rule upper(Native(S)) => Native(upperAscii(S)) requires asciiMethod(S)
  rule upper(Unicode(S)) => Unicode(upperAscii(S)) requires asciiMethod(S)
  rule upper(Bytes3(S)) => Bytes3(upperAscii(S)) requires asciiMethod(S)
  rule upper(None) => None

  // Existing compatibility helper: native strings pass through; non-native
  // strings convert to the runtime native string type under ASCII.
  rule toNative(Py2, Native(S)) => Native(S) requires asciiMethod(S)
  rule toNative(Py2, Unicode(S)) => Native(S) requires asciiMethod(S)
  rule toNative(Py3, Native(S)) => Native(S) requires asciiMethod(S)
  rule toNative(Py3, Bytes3(S)) => Native(S) requires asciiMethod(S)

  // V1 implementation of PreparedRequest.prepare_method().
  rule prepareMethod(PY, None) => None
  rule prepareMethod(PY, M) => toNative(PY, upper(M)) requires M =/=K None

  // Session.prepare_request applies an earlier .upper() before prepare_method.
  rule sessionPrepareRequestMethod(PY, M) => prepareMethod(PY, upper(M))

  // Session.request applies .upper(), then Session.prepare_request applies
  // another .upper(), then PreparedRequest.prepare_method() applies the final
  // normalization.
  rule sessionRequestMethod(PY, M) => prepareMethod(PY, upper(upper(M)))

  // String-theory lemmas used by the constructed proof.
  rule upperAscii(upperAscii(S)) => upperAscii(S) requires asciiMethod(S)
endmodule

