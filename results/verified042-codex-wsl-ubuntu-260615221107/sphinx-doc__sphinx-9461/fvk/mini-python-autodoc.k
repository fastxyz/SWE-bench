// Constructed FVK sketch for sphinx-doc__sphinx-9461.
// This is a reduced semantics for autodoc class member lookup.
// It was not compiled or machine-checked in this benchmark session.

module MINI-PYTHON-AUTODOC-SYNTAX
  syntax Id ::= r"[A-Za-z_][A-Za-z0-9_]*" [token]
  syntax Value ::= "prop(" Id ")"
                 | "classmethodProperty(" Id ")"
                 | "other(" Id ")"
                 | "attrget(" Id "," Id "," Id ")"
                 | "doc(" Id ")"
  syntax Lookup ::= "getClassMember(" Id "," Id "," Id ")"
                  | "propertyDocumenterImport(" Id ")"
endmodule

module MINI-PYTHON-AUTODOC
  imports MINI-PYTHON-AUTODOC-SYNTAX

  // Abstract predicates/functions used by the spec file:
  // - firstDefines(SUBJECT, NAME, CLS)
  // - firstMissing(SUBJECT, NAME)
  // - isClass(SUBJECT)
  // - docAttrgetter(DOC)
  // - parent(DOC)
  // - objectName(DOC)
  //
  // The full Python descriptor protocol is intentionally outside this reduced
  // fragment. The proof treats class dictionary lookup and attrgetter fallback
  // as the observable transitions relevant to the issue.
endmodule
