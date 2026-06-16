module MINI-PYTHON-MOCK-SYNTAX
  imports STRING-SYNTAX

  syntax PyName ::= PyString(String)
                  | TypeVarName(String)
                  | NamedObjectName(String)
                  | ReprObjectName(String)
                  | MockObjectName(String)

  syntax PyType ::= mkPyType(String, String, String)
  syntax PyInstance ::= mkPyInstance(PyType)

  syntax Exp ::= makeSubclassName(PyName)
               | makeSubclass(PyName, String, String)
               | mockGetItem(String, String, PyName)

  syntax KResult ::= String | PyType | PyInstance
endmodule

module MINI-PYTHON-MOCK
  imports MINI-PYTHON-MOCK-SYNTAX
  imports STRING

  configuration <k> $PGM:Exp </k>

  syntax String ::= normalizedName(PyName) [function]

  rule normalizedName(PyString(S)) => S
  rule normalizedName(TypeVarName(S)) => S
  rule normalizedName(NamedObjectName(S)) => S
  rule normalizedName(ReprObjectName(S)) => S
  rule normalizedName(MockObjectName(S)) => S

  rule <k> makeSubclassName(N) => normalizedName(N) </k>

  rule <k> makeSubclass(N, MODULE, SUPER)
        => mkPyType(normalizedName(N), SUPER, MODULE +String "." +String normalizedName(N))
       </k>

  rule <k> mockGetItem(DISPLAY, CLASS, KEY)
        => mkPyInstance(mkPyType(normalizedName(KEY),
                                 CLASS,
                                 DISPLAY +String "." +String normalizedName(KEY)))
       </k>
endmodule
