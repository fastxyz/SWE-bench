// Constructed, not machine-checked.
// Exact commands to check later:
//   kompile fvk/mini-python-domain.k --backend haskell
//   kast --backend haskell fvk/python-domain-index-spec.k
//   kprove fvk/python-domain-index-spec.k

requires "mini-python-domain.k"

module PYTHON-DOMAIN-INDEX-SPEC
  imports MINI-PYTHON-DOMAIN

  // SPEC-PROVENANCE:
  // - from_prompt: "py:method directive with :property: option ... should not have parens"
  //   => every property-option index entry must be property-shaped.
  // - from_code: PyMethod.get_index_text splits a qualified name on the final dot.
  claim
    <k> getIndexText(opts(true, CM:Bool, SM:Bool), MOD:ModName, ADD:Bool,
                     qualified(CLS:String, METH:String))
     => propertyClass(METH, displayClass(MOD, ADD, CLS)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "An index entry for the property should not have parens."
  //   => unqualified property-option entries must also avoid method-shaped text.
  // - from_code: the ValueError path handles names without a dot.
  claim
    <k> getIndexText(opts(true, CM:Bool, SM:Bool), mod(MOD:String), ADD:Bool,
                     unqualified(NAME:String))
     => propertyModule(NAME, MOD) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: property entries should not have parens.
  // - from_code: the no-module ValueError path returns the bare name.
  claim
    <k> getIndexText(opts(true, CM:Bool, SM:Bool), noMod, ADD:Bool,
                     unqualified(NAME:String))
     => propertyPlain(NAME) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the defect is tied to the presence of :property:.
  // - from_code: V2 places the property branch before classmethod/staticmethod.
  claim
    <k> hasCallableParens(getIndexText(opts(true, CM:Bool, SM:Bool), MOD:ModName,
                                      ADD:Bool, NAME:NameShape))
     => false </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_compatibility: non-property method/classmethod/staticmethod entries are not in the issue.
  // - from_code: when property is false, V2 follows the pre-existing callable branches.
  claim
    <k> hasCallableParens(getIndexText(opts(false, CM:Bool, SM:Bool), MOD:ModName,
                                      ADD:Bool, NAME:NameShape))
     => true </k>
    [all-path]
endmodule
