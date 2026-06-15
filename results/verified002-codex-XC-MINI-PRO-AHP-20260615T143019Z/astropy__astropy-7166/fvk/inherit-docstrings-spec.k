// Constructed, not machine-checked.
// Claims for the InheritDocstrings.__init__ audit over the mini semantics.

requires "mini-python-inherit-docstrings.k"

module INHERIT-DOCSTRINGS-SPEC
  imports MINI-PYTHON-INHERIT-DOCSTRINGS

  // SPEC-PROVENANCE:
  // - from_prompt: "InheritDocstrings metaclass doesn't work for properties"
  //   => subclass properties with missing docs inherit the overridden docstring.
  // - from_prompt: "inspect.isfunction ... returns False for properties"
  //   => eligibility must include data descriptors, not only functions.
  claim inheritIfNeeded(
          member(dataDescriptor, true, noneDoc, true),
          found(member(dataDescriptor, true, doc("base doc"), true)))
     => member(dataDescriptor, true, doc("base doc"), true)

  // SPEC-PROVENANCE:
  // - from_existing_doc: "methods ... automatically have their docstrings"
  //   => existing function behavior is preserved.
  claim inheritIfNeeded(
          member(function, true, noneDoc, true),
          found(member(function, true, doc("base doc"), true)))
     => member(function, true, doc("base doc"), true)

  // SPEC-PROVENANCE:
  // - from_prompt: "redefine it without setting the docstring"
  //   => explicit subclass docs are not overwritten.
  claim inheritIfNeeded(
          member(dataDescriptor, true, doc("sub doc"), true),
          found(member(dataDescriptor, true, doc("base doc"), true)))
     => member(dataDescriptor, true, doc("sub doc"), true)

  // SPEC-PROVENANCE:
  // - from_existing_doc/public API: non-function and non-descriptor values
  //   were not part of the old inheritance contract and remain unchanged.
  claim inheritIfNeeded(
          member(other, true, noneDoc, true),
          found(member(other, true, doc("base doc"), true)))
     => member(other, true, noneDoc, true)

  // SPEC-PROVENANCE:
  // - from_existing_doc/public API: the existing public-member filter excludes
  //   private non-dunder names from inherited-doc mutation.
  claim inheritIfNeeded(
          member(dataDescriptor, false, noneDoc, true),
          found(member(dataDescriptor, true, doc("base doc"), true)))
     => member(dataDescriptor, false, noneDoc, true)

  // SPEC-PROVENANCE:
  // - from_public_compatibility: broadening to data descriptors must not make
  //   class creation fail for descriptors whose __doc__ cannot be assigned.
  claim inheritIfNeeded(
          member(dataDescriptor, true, noneDoc, false),
          found(member(dataDescriptor, true, doc("base doc"), true)))
     => member(dataDescriptor, true, noneDoc, false)

  // SPEC-PROVENANCE:
  // - from_code_review: descriptor lookup uses inspect.getattr_static so the
  //   inherited descriptor object is inspected rather than invoked.
  claim lookupMode(member(dataDescriptor, true, noneDoc, true))
     => staticLookup
endmodule
