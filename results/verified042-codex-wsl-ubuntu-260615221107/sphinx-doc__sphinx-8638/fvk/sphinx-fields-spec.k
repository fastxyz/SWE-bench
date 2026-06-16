// Formal claims for sphinx-doc__sphinx-8638.
// Status: constructed, not machine-checked.

requires "mini-sphinx-fields.k"

module SPHINX-FIELDS-SPEC
  imports MINI-SPHINX-FIELDS

  // SPEC-PROVENANCE:
  // - from_prompt: "Expected behavior: That the class variable documentation
  //   not be linked to any other." => variable field labels are plain labels.
  // - from_docs: "`var`, `ivar`, `cvar`: Description of a variable." =>
  //   no documented link obligation for the field label.
  // - from_code: Field.make_xref returns plain content when rolename is falsey.
  // CLAIM: VARIABLE-FIELD-NO-XREF
  claim
    <k> variableField(noRole, NAME:String, BODY:String, OBJECTS:Objects)
     => renderedField(plain(NAME), plain(BODY)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: "`vartype`: Type of a variable. Creates a link if possible."
  //   => type text stays a class-role pending xref.
  // - from_code: V1 keeps typerolename='class' on the variable typed field.
  // CLAIM: VARIABLE-FIELD-WITH-TYPE-PRESERVES-TYPE-XREF
  claim
    <k> variableFieldWithType(noRole, classRole, NAME:String, TYPE:String,
                              BODY:String, OBJECTS:Objects)
     => renderedFieldWithType(plain(NAME), pending(classRole, TYPE), plain(BODY)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: users can explicitly write a reference such as
  //   `see :const:`somename`` => explicit roles remain opt-in links.
  // - from_code: V1 does not change PythonDomain.roles or find_obj.
  // CLAIM: EXPLICIT-REFERENCE-STILL-LINKS
  claim
    <k> explicitReference(dataRole, NAME:String, moduleSameName)
     => linked(NAME, "module-data") </k>
    [all-path]
endmodule
