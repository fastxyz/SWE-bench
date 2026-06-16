# Baseline Notes

## Root cause

Autodoc already parses next-line string literals and `#:` comments as attribute
documentation, but type aliases can be documented through two special fallback
paths before that documentation is emitted.

On Python versions where `typing` aliases are generic aliases,
`GenericAliasMixin.update_content()` always appended generated `alias of ...`
content. On Python 3.6-style `typing` aliases, some aliases such as `Dict[...]`
and `Callable[...]` can be selected by `ClassDocumenter` and handled as class
aliases via `doc_as_attr`; that path returned no docstring and replaced the
content with `alias of ...`. `Union[...]` follows a different data-documenter
path, which is why the issue was inconsistent.

## Changed files

`repo/sphinx/ext/autodoc/__init__.py`

- Added a `has_docstring_comment()` hook for data/attribute documenter mixins.
- Made the GenericAlias, NewType, and TypeVar fallback text conditional on the
  absence of an explicit source docstring-comment.
- Taught `DataDocumenter` and `AttributeDocumenter` to report whether their
  source-level docstring-comment exists, using the same analyzer lookups they
  already use for `get_doc()`.
- Taught `ClassDocumenter` aliases to look up docstring-comments in the aliasing
  module/class scope. When such a comment exists, autodoc now emits that comment
  instead of the generated `alias of ...` fallback.

## Assumptions and alternatives

I treated the next-line string literal in the issue as explicit attribute
documentation, equivalent to the existing autodoc "docstring-comment" support.
When explicit documentation exists, it should replace the fallback alias text
rather than be combined with it.

I considered changing the parser, but rejected that because the parser already
records all three aliases' comments. The inconsistent behavior happens later,
when different documenters decide whether to synthesize fallback content.

I also considered forcing all type aliases through `DataDocumenter`, but rejected
that as broader and riskier. The fix instead preserves the existing documenter
selection and only changes whether generated fallback text is emitted.
