# Formal Spec In English

1. For every data alias kind modeled (`GenericAlias`, `NewType`, `TypeVar`), if
   a source docstring-comment exists, autodoc emits user doc content and does
   not emit generated alias fallback content.
2. For every attribute alias kind modeled, if a source docstring-comment exists,
   autodoc emits user doc content and does not emit generated alias fallback
   content.
3. For a `ClassDocumenter.doc_as_attr` alias, if a source docstring-comment
   exists in the aliasing module/class scope, autodoc emits user doc content,
   does not emit generated alias fallback content, and records the aliasing
   source file as a dependency.
4. For modeled aliases without a source docstring-comment, generated fallback
   content remains available.
