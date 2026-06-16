requires "mini-python-mock.k"

module AUTODOC-MOCK-SPEC
  imports MINI-PYTHON-MOCK
  imports STRING

  // SPEC-PROVENANCE:
  // - from_prompt: "mock._make_subclass attempts to concatenate a str to a TypeVar"
  //   => non-string generic parameters must be normalized before display-name concatenation.
  // - from_prompt: "Docs can still be built when generics are involved"
  //   => mock generic subscription must not fail before autodoc can continue.
  // - from_public_tests: repr(mock.some_attr) == "mocked_module.some_attr"
  //   => preserve existing dotted display-name behavior for string names.
  // - from_code: _MockObject.__getitem__ calls _make_subclass(key, display, cls)().
  claim
    <k> makeSubclass(TypeVarName(T:String), MODULE:String, SUPER:String)
      => mkPyType(T, SUPER, MODULE +String "." +String T)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: existing mock attribute names are strings and display as module.name.
  // - from_code: _make_subclass is shared by attribute access, module getattr, class creation,
  //   and generic subscription.
  claim
    <k> makeSubclass(PyString(NAME:String), MODULE:String, SUPER:String)
      => mkPyType(NAME, SUPER, MODULE +String "." +String NAME)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: generic typing may pass typing objects rather than strings.
  // - from_default_domain: Python TypeVar objects expose a string __name__; other ordinary
  //   objects have a string repr(), represented by ReprObjectName.
  claim
    <k> makeSubclass(N:PyName, MODULE:String, SUPER:String)
      => mkPyType(normalizedName(N),
                  SUPER,
                  MODULE +String "." +String normalizedName(N))
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: docs for generic-typed classes should build.
  // - from_code: _MockObject.__getitem__ returns _make_subclass(key, display, cls)().
  claim
    <k> mockGetItem(DISPLAY:String, CLASS:String, TypeVarName(T:String))
      => mkPyInstance(mkPyType(T, CLASS, DISPLAY +String "." +String T))
    </k>
    [all-path]
endmodule
