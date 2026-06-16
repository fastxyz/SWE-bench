// Constructed FVK sketch for sphinx-doc__sphinx-9461.
// Claims are not machine-checked in this benchmark session.

requires "mini-python-autodoc.k"

module AUTODOC-CLASS-PROPERTY-SPEC
  imports MINI-PYTHON-AUTODOC

  // SPEC-PROVENANCE:
  // - from_prompt: "@classmethod and @property do not get documented"
  //   => autodoc must receive the wrapped property, not the computed value.
  claim
    <k> getClassMember(SUBJECT, NAME, ATTRGETTER) => prop(PROP) ... </k>
    <raw> CLS , NAME |-> classmethodProperty(PROP) </raw>
    requires firstDefines(SUBJECT, NAME, CLS)

  // SPEC-PROVENANCE:
  // - from_prompt: "regular @property decorated methods get documented just fine"
  //   => non-wrapper members keep existing attrgetter behavior.
  claim
    <k> getClassMember(SUBJECT, NAME, ATTRGETTER)
      => attrget(ATTRGETTER, SUBJECT, NAME) ... </k>
    <raw> CLS , NAME |-> other(RAW) </raw>
    requires firstDefines(SUBJECT, NAME, CLS)

  // SPEC-PROVENANCE:
  // - from_default_domain: Python class lookup uses MRO order
  //   => subclass definitions shadow base class wrappers.
  claim
    <k> getClassMember(SUBCLASS, NAME, ATTRGETTER)
      => attrget(ATTRGETTER, SUBCLASS, NAME) ... </k>
    <raw> SUBCLASS , NAME |-> other(SUB_RAW) </raw>
    <raw> BASE , NAME |-> classmethodProperty(BASE_PROP) </raw>
    requires firstDefines(SUBCLASS, NAME, SUBCLASS)

  // SPEC-PROVENANCE:
  // - from_prompt: Sphinx lacks a chance to extract the docstring after
  //   descriptor evaluation
  //   => PropertyDocumenter must replace the imported object with helper output.
  claim
    <k> propertyDocumenterImport(DOC) => doc(DOC2) ... </k>
    <parent> DOC |-> PARENT </parent>
    <objectName> DOC |-> NAME </objectName>
    <object> DOC2 |-> RESULT </object>
    requires isClass(PARENT)
     andBool RESULT ==K getClassMember(PARENT, NAME, docAttrgetter(DOC))
endmodule
