// Constructed, not machine-checked.
// SPEC-PROVENANCE:
// - from_prompt: "The docs should show the contents in the docstrings for all
//   the type aliases instead of the the ``alias of ...`` default text."
//   => documented type aliases must render user doc content and suppress the
//      generated alias fallback.
// - from_prompt: the reduced example includes Dict, Union, and Callable aliases
//   with next-line triple-quoted docstrings.
//   => the obligation covers the family of type-alias documenter routes, not
//      only the Union/data route that already worked.
// - from_code: ModuleAnalyzer records next-line string literals as attr_docs;
//   DataDocumenter, AttributeDocumenter, GenericAliasMixin, NewTypeMixin,
//   TypeVarMixin, and ClassDocumenter jointly produce the observable content.
// - from_code: ClassDocumenter doc_as_attr aliases read comments from the
//   aliasing module; using that source also requires recording that analyzer
//   source as a dependency.

requires "mini-autodoc-alias.k"

module AUTODOC-ALIAS-SPEC
  imports MINI-AUTODOC-ALIAS

  claim <k> renderDataAlias(K:AliasKind, true)
        => result(true, false, false) ... </k>
    [label(DATA-DOC-COMMENT-SUPPRESSES-FALLBACK)]

  claim <k> renderAttributeAlias(K:AliasKind, true)
        => result(true, false, false) ... </k>
    [label(ATTRIBUTE-DOC-COMMENT-SUPPRESSES-FALLBACK)]

  claim <k> renderClassAlias(true)
        => result(true, false, true) ... </k>
    [label(CLASS-ALIAS-DOC-COMMENT-SUPPRESSES-FALLBACK-AND-RECORDS-DEPENDENCY)]

  claim <k> renderDataAlias(K:AliasKind, false)
        => result(false, true, false) ... </k>
    [label(DATA-UNDOCUMENTED-ALIAS-KEEPS-FALLBACK)]

  claim <k> renderAttributeAlias(K:AliasKind, false)
        => result(false, true, false) ... </k>
    [label(ATTRIBUTE-UNDOCUMENTED-ALIAS-KEEPS-FALLBACK)]

  claim <k> renderClassAlias(false)
        => result(false, true, false) ... </k>
    [label(CLASS-UNDOCUMENTED-ALIAS-KEEPS-FALLBACK)]
endmodule
