requires "mini-sphinx-mock.k"

module MOCK-BASE-SPEC
  imports MINI-SPHINX-MOCK

  // SPEC-PROVENANCE:
  // - from_prompt: "The 'Bases' section should report `torch.nn.Module`
  //   not `torch.nn.`." => mocked base rendering must preserve the final
  //   class-name component.
  // - from_code: _make_subclass("Module", "torch.nn") creates a mock class
  //   with module "torch.nn"; V1 initializes the mock instance qualname from
  //   that class qualname.
  claim <k>
      restify(initMock(makeSubclass("Module", "torch.nn")))
        => ":py:class:`torch.nn.Module`"
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the issue is not torch-specific; it concerns inherited
  //   mocked classes generally.
  // - from_default_domain: mocked module paths and attribute names are strings;
  //   restify renders module + "." + qualname.
  claim <k>
      restify(initMock(makeSubclass(N:String, M:String)))
        => ":py:class:`" +String M +String "." +String N +String "`"
    </k>
    [all-path]
endmodule
