# Public Compatibility Audit

## Changed Symbols

`sphinx.ext.autodoc.ClassDocumenter.get_docstring_comment`

- New internal helper.
- No public signature compatibility issue.

`sphinx.ext.autodoc.DataDocumenterMixinBase.has_docstring_comment`

- New internal hook used by mixins.
- Default implementation returns `False`, preserving behavior for subclasses
  that do not override it.

`sphinx.ext.autodoc.DataDocumenter.has_docstring_comment`

- New internal override.
- No public callsite impact.

`sphinx.ext.autodoc.AttributeDocumenter.has_docstring_comment`

- New internal override.
- No public callsite impact.

## Public API Shape

No directive names, directive options, event names, event argument lists,
documenter constructors, or documented config values changed.

## Subclass/Override Risk

External subclasses that inherit the modified mixins but do not override
`has_docstring_comment()` keep the default `False` behavior. External subclasses
that override `update_content()` are unaffected unless they opt into the new
helper.

## Producer/Consumer Shape

Generated content remains a `StringList`/line stream. The only intended content
shape change is the issue-required suppression of generated fallback lines when
source docstring-comments exist.
