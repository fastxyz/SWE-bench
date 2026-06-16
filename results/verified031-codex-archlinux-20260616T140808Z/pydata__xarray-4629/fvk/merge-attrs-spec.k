requires "mini-python.k"

module MERGE-ATTRS-SPEC-SYNTAX
  imports MINI-PYTHON-ATTRS-SYNTAX
endmodule

module MERGE-ATTRS-VERIFICATION
  imports MERGE-ATTRS-SPEC-SYNTAX
  imports MINI-PYTHON-ATTRS
  imports INT
  imports BOOL
  imports MAP
  imports K-EQUAL
endmodule

module MERGE-ATTRS-SPEC
  imports MERGE-ATTRS-VERIFICATION

  // SPEC-PROVENANCE:
  // - from_prompt: "does not copy attrs but instead references attrs from the first object"
  //   => result attrs must not be the first attrs object.
  // - from_prompt: "should be able to be changed without having any effect on the sources"
  //   => result object identity differs from first source identity.
  // - from_docs: "copy attrs from the first dataset to the result"
  //   => result contents equal first source contents.
  // - from_code: V1 uses dict(variable_attrs[0]), modeled as attr(N, M0)
  //   with fresh allocator id N.
  claim
    <k> mergeAttrs(consAttr(attr(ID0:Int, M0:Map), REST:AttrList), override)
      => attr(N:Int, M0) ... </k>
    <nextId> N => N +Int 1 </nextId>
    requires N =/=Int ID0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: combine_attrs='drop' means empty attrs on returned object.
  claim
    <k> mergeAttrs(consAttr(attr(ID0:Int, M0:Map), REST:AttrList), drop)
      => attr(N:Int, .Map) ... </k>
    <nextId> N => N +Int 1 </nextId>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: empty variable_attrs returns None before mode dispatch.
  claim
    <k> mergeAttrs(emptyAttrs, MODE:Mode) => none ... </k>
    <nextId> N:Int </nextId>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: no_conflicts combines compatible attrs.
  // - from_code: branch starts from dict(variable_attrs[0]), so result object is fresh.
  claim
    <k> mergeAttrs(ATTRS:AttrList, noConflicts)
      => attr(N:Int, unionNoConflicts(ATTRS)) ... </k>
    <nextId> N => N +Int 1 </nextId>
    requires ATTRS =/=K emptyAttrs andBool compatibleNoConflicts(ATTRS)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: identical requires all attrs to match.
  // - from_code: branch starts from dict(variable_attrs[0]), so result object is fresh.
  claim
    <k> mergeAttrs(ATTRS:AttrList, identical)
      => attr(N:Int, firstContents(ATTRS)) ... </k>
    <nextId> N => N +Int 1 </nextId>
    requires ATTRS =/=K emptyAttrs andBool allIdentical(ATTRS)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: unknown combine_attrs raises ValueError.
  claim
    <k> mergeAttrs(consAttr(attr(ID0:Int, M0:Map), REST:AttrList), badMode)
      => valueError ... </k>
    <nextId> N:Int </nextId>
    [all-path]
endmodule
