# Baseline Notes

## Root cause

Autodoc parsed attribute doc-comments into `ModuleAnalyzer.attr_docs` using
`(namespace, attrname)` keys, but class member filtering and attribute content
generation only looked up the namespace of the class currently being documented.
For an inherited data attribute such as `Inherited.ham`, the runtime member was
visible on `Inherited`, but its comment docstring was cached as `("Base", "ham")`.
As a result, `:inherited-members:` treated the attribute as undocumented and
skipped it unless `:undoc-members:` was also used. Explicit `autoattribute` for
the inherited attribute had the same namespace mismatch when adding content.

## Changed files

### `repo/sphinx/ext/autodoc/importer.py`

Added a class-aware attribute doc-comment lookup helper that walks a class MRO
and reads the analyzed source for each class's defining module. `get_class_members()`
now records the class that actually defines each inherited runtime member and
uses this helper to attach comment docstrings only from that defining class. It
still only synthesizes missing instance-attribute members for the class currently
being documented, preserving the existing boundary around inherited instance-only
attributes.

### `repo/sphinx/ext/autodoc/__init__.py`

Refactored `Documenter.add_content()` to ask a `get_attribute_comment()` hook for
attribute comments instead of hard-coding one `(namespace, attrname)` lookup.
`AttributeDocumenter` inherits an override through
`UninitializedInstanceAttributeMixin` that first preserves the existing direct
lookup, then falls back to the new class/MRO-aware lookup. This lets explicit
`autoattribute` render a base-class attribute comment when documenting the
attribute through a subclass. Member filtering also marks injected ObjectMember
docstrings as attribute documentation so inherited documented data attributes are
handled as attributes.

## Assumptions and alternatives

The issue example and later discussion distinguish class/data attributes from
inherited instance attributes, so this fix targets inherited runtime attributes
and explicit attribute directives while avoiding a broader change that would add
base-class `self.attr` comments to every subclass member list. That broader
interpretation was rejected because it would change the behavior of
`:inherited-members:` for instance-only attributes and could interact poorly with
existing superclass cutoff filtering.

I also considered changing only `filter_members()`, but that would only make the
inherited attribute appear in `autoclass` output; the generated `autoattribute`
documenter would still fail to find and render the inherited comment body. The
final change fixes both member inclusion and content generation.
