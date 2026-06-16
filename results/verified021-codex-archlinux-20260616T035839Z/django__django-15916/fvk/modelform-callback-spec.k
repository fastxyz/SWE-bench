requires "mini-python-form-callback.k"

module MODELFORM-CALLBACK-SPEC
  imports MINI-PYTHON-FORM-CALLBACK

  // SPEC-PROVENANCE:
  // - E2/E3: Meta.formfield_callback must be supported as a ModelForm option.
  claim <k> resolve(absent, cbMeta) => cbMeta </k>
    [label(META-DIRECT)]

  // SPEC-PROVENANCE:
  // - E5: explicit factory/top-level callback behavior is public behavior.
  claim <k> resolve(present(cbTop), cbMeta) => cbTop </k>
    [label(TOP-LEVEL-OVERRIDE)]

  // SPEC-PROVENANCE:
  // - E5: a top-level class attribute is explicit, including explicit None.
  claim <k> resolve(present(cbNone), cbMeta) => cbNone </k>
    [label(TOP-LEVEL-NONE-DISABLES)]

  // SPEC-PROVENANCE:
  // - E1/E2: omitted factory callback must preserve base Meta callback.
  claim <k> factoryClassAttrs(cbNone, cbMeta) => cbMeta </k>
    [label(FACTORY-OMITTED-PRESERVES-META)]

  // SPEC-PROVENANCE:
  // - E5: non-None factory argument explicitly overrides inherited Meta.
  claim <k> factoryClassAttrs(cbFactory, cbMeta) => cbFactory </k>
    [label(FACTORY-EXPLICIT-OVERRIDES-META)]

  // SPEC-PROVENANCE:
  // - E6: explicit callback detection is identity-with-None, not truthiness.
  claim <k> factoryClassAttrs(cbFalsey, cbMeta) => cbFalsey </k>
    [label(FACTORY-FALSEY-NON-NONE-OVERRIDES)]

  // SPEC-PROVENANCE:
  // - E4: a child with no Meta uses the first parent's Meta.
  claim <k> childWithInheritedMeta(cbBase) => cbBase </k>
    [label(INHERITED-META-PRESERVES)]

  // SPEC-PROVENANCE:
  // - E3/E4: a replacement Meta wins and must not receive a special base
  //   callback fallback. This was the V1 finding fixed in V2.
  claim <k> childWithReplacedMeta(cbBase) => cbNone </k>
    [label(REPLACED-META-DOES-NOT-LEAK-BASE)]
endmodule
