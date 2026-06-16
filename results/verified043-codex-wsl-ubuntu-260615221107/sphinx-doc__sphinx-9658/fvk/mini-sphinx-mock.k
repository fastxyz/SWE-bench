module MINI-SPHINX-MOCK-SYNTAX
  imports STRING-SYNTAX

  syntax MockClass ::= mockClass(String, String, String)
  syntax MockObj ::= mockObj(String, String, String)

  syntax MockClass ::= makeSubclass(String, String) [function]
  syntax MockObj ::= initMock(MockClass) [function]
  syntax String ::= restify(MockObj) [function]

  syntax KResult ::= MockClass | MockObj | String
endmodule

module MINI-SPHINX-MOCK
  imports MINI-SPHINX-MOCK-SYNTAX
  imports STRING

  configuration <k> $PGM:K </k>

  // Abstracts _make_subclass(name, module): Python type(name, ...) gives
  // the generated class the short qualified name `name`.
  rule makeSubclass(N:String, M:String) => mockClass(N, M, N)

  // Abstracts _MockObject.__init__ after V1: the instance qualname is copied
  // from the generated class qualname.
  rule initMock(mockClass(N:String, M:String, Q:String))
    => mockObj(M, Q, M +String "." +String N)

  // Abstracts sphinx.util.typing.restify() on a mock instance carrying
  // __module__ and __qualname__.
  rule restify(mockObj(M:String, Q:String, _D:String))
    => ":py:class:`" +String M +String "." +String Q +String "`"
endmodule
