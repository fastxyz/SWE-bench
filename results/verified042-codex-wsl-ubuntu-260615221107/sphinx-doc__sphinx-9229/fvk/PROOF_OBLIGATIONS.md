# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Source Docstring-Comment Detection

If a next-line string literal or `#:` comment documents an alias assignment, the
module analyzer exposes a key in `attr_docs` for that alias scope/name. This is
implementation evidence from `Parser.visit_Expr()` and existing analyzer use.

## PO2: Data Alias Content Selection

For `DataDocumenter` alias kinds `GenericAlias`, `NewType`, and `TypeVar`:

- If `has_docstring_comment()` is true, `get_doc()` returns that comment and
  `update_content()` must not append fallback text.
- If `has_docstring_comment()` is false, existing fallback generation remains
  available for supported alias kinds.

Formal claims: `DATA-DOC-COMMENT-SUPPRESSES-FALLBACK` and
`DATA-UNDOCUMENTED-ALIAS-KEEPS-FALLBACK`.

## PO3: Attribute Alias Content Selection

For `AttributeDocumenter` alias kinds `GenericAlias`, `NewType`, and `TypeVar`:

- If `has_docstring_comment()` is true, `get_doc()` returns that comment and
  `update_content()` must not append fallback text.
- If `has_docstring_comment()` is false, existing fallback generation remains
  available for supported alias kinds.

Formal claims: `ATTRIBUTE-DOC-COMMENT-SUPPRESSES-FALLBACK` and
`ATTRIBUTE-UNDOCUMENTED-ALIAS-KEEPS-FALLBACK`.

## PO4: Class Alias Content Selection

For `ClassDocumenter.doc_as_attr` aliases:

- If the aliasing module/class scope has a docstring-comment, `get_doc()` must
  return that comment and `add_content()` must not replace content with
  generated fallback text.
- If no docstring-comment exists, generated fallback text remains the legacy
  output.

Formal claims:
`CLASS-ALIAS-DOC-COMMENT-SUPPRESSES-FALLBACK-AND-RECORDS-DEPENDENCY` and
`CLASS-UNDOCUMENTED-ALIAS-KEEPS-FALLBACK`.

## PO5: Dependency Tracking

When `ClassDocumenter.get_docstring_comment()` uses `ModuleAnalyzer` for the
aliasing module and finds source content, it must add `analyzer.srcname` to
`directive.record_dependencies`.

Formal claim:
`CLASS-ALIAS-DOC-COMMENT-SUPPRESSES-FALLBACK-AND-RECORDS-DEPENDENCY`.

## PO6: Public Compatibility

The fix must not change public directive options, documenter constructor
signatures, event signatures, or output paths for undocumented aliases. The new
methods are additive internal helpers.

## PO7: Scope Boundary

The proof covers source docstring-comments and generated fallback content. It
does not decide behavior for manual directive body content, custom extension
event mutation, or failed source parsing beyond treating them as outside the
documented-alias source-comment case.

## PO8: Machine-Check Commands

These commands are emitted but intentionally not run:

```sh
kompile fvk/mini-autodoc-alias.k --backend haskell
kast --backend haskell fvk/autodoc-alias-spec.k
kprove fvk/autodoc-alias-spec.k
```

Expected machine-check result after syntax/module adjustments, if any are needed
for a local K installation: `#Top` for all six claims.
