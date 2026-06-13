# Baseline notes — sphinx-doc__sphinx-8548

## Issue

`autodoc`'s `:inherited-members:` works for inherited *methods* but not for
inherited *attributes* (data members). For example:

```python
class Base:
    """The base class."""

    #: A base attribute.
    ham = True

    def eggs(self):
        """A base method."""


class Inherited(Base):
    """The subclass."""

    #: A local attribute.
    foo = 3
```

```rst
.. autoclass:: example.Inherited
    :inherited-members:
```

`Base.eggs` (a method) shows up under `Inherited`, but `Base.ham` (a
comment-documented data attribute) does not. The same problem affects inherited
*instance* attributes (`self.ham = True  #: ...` defined in `Base.__init__`),
and `autoattribute` on an inherited attribute.

## Root cause

A comment-based docstring (`#: ...` or a string literal after the assignment) is
stored by the source-code analyzer (`sphinx.pycode.ModuleAnalyzer`) keyed by the
**defining class**: `attr_docs[(qualname_of_defining_class, attrname)]`. So
`Base.ham`'s doc is stored under `('Base', 'ham')`.

When autodoc documents `Inherited`, it looked up attribute docs using only the
**current** class as the namespace (`'Inherited'`), never consulting base
classes. This happened in two cooperating places:

1. `sphinx/ext/autodoc/importer.py:get_class_members()` — when collecting the
   members of a class it only matched `analyzer.attr_docs` whose namespace equals
   `'.'.join(objpath)` (the current class). Result: an inherited class attribute
   such as `ham` was discovered via `dir()` but carried **no docstring**, and an
   inherited *instance* attribute was not discovered at all.

2. `sphinx/ext/autodoc/__init__.py:Documenter.add_content()` /
   `AttributeDocumenter.get_doc()` — the `AttributeDocumenter` created for
   `Inherited.ham` looked for `('Inherited', 'ham')` in `attr_docs` and, finding
   nothing, produced no docstring.

Because `ham` ended up "undocumented" (no `__doc__`, no comment doc found),
`Documenter.filter_members()` dropped it (members are kept only if documented,
unless `:undoc-members:` is given). Methods were unaffected because a method's
docstring lives on the function object's `__doc__`, which `getdoc()` resolves
through normal attribute inheritance.

This is exactly the "comment based docstring is strongly coupled with its class"
problem described in the issue thread.

## Fix

The fix makes both member discovery and docstring retrieval walk the MRO so an
inherited attribute can find the comment docstring defined on the base class
where the attribute actually lives.

### `sphinx/ext/autodoc/importer.py`

- Added `PycodeError` to the `from sphinx.pycode import ...` import.
- Rewrote the final "append instance attributes" block of `get_class_members()`.
  Instead of consulting a single analyzer for the current namespace, it now
  iterates over `getmro(subject)`; for each class it loads that class's module
  analyzer and matches `attr_docs` entries whose namespace equals the class's
  `__qualname__`. For each match it either:
  - adds a new member (`INSTANCEATTR`) with the comment as its docstring — this
    covers inherited *instance* attributes that are invisible to `dir()`; or
  - attaches the comment docstring to an already-discovered member whose
    `docstring` is still `None` — this covers inherited *class-level* attributes
    (e.g. `ham`) that `dir()` already surfaced but without a docstring.

  MRO order (most-derived first) ensures a subclass that re-documents an
  attribute wins over the base class. Loading each analyzer is wrapped in
  `try/except (AttributeError, PycodeError)` so builtins / C modules (e.g.
  `object`) are skipped gracefully.

  With this, `get_class_members()` returns inherited attributes carrying their
  docstrings, so `ClassDocumenter.get_object_members()` (which already passes the
  docstring through `ObjectMember`) and `filter_members()` (which already honors
  `ObjectMember.docstring` for the "has_doc" decision) keep the member instead of
  discarding it as undocumented.

### `sphinx/ext/autodoc/__init__.py`

- `AttributeDocumenter.get_doc()` now first calls the existing
  `get_attribute_comment(self.parent)` helper (defined in
  `UninitializedInstanceAttributeMixin`, which `AttributeDocumenter` already
  inherits). That helper walks `getmro(parent)` and returns the comment for
  `(qualname, attrname)` from whichever class in the MRO defines it. If a comment
  is found it is returned as the docstring; otherwise the previous behavior is
  unchanged.

  This is what actually emits the inherited comment when the per-attribute
  `AttributeDocumenter` runs for `Inherited.ham` (and for a direct
  `.. autoattribute:: example.Inherited.ham`). For an attribute defined on the
  current class, `Documenter.add_content()` still finds it via its normal
  `('current', name)` `attr_docs` lookup and never reaches `get_doc()`, so there
  is no double emission.

## Why these two changes together

Both are required:

- Without the `importer.py` change, `filter_members()` still considers `ham`
  undocumented and removes it before any `AttributeDocumenter` is created.
- Without the `__init__.py` change, even a kept `ham` would render with an empty
  body because the per-attribute documenter could not locate the base-class
  comment.

## Assumptions / alternatives considered

- **Reusing `get_attribute_comment` vs. adding a new helper.** The mixin already
  contained an MRO-walking comment lookup keyed by `self.objpath[-1]`, which is
  precisely what's needed, so I reused it rather than duplicating logic. Its
  signature was left unchanged (no need to thread an explicit `attrname`).

- **Putting the comment check in `get_doc` vs. `add_content`.** I chose
  `get_doc` because `Documenter.add_content` already falls back to `get_doc()`
  when the current-namespace `attr_docs` lookup misses, giving a clean,
  single-emission path for the inherited case while leaving the local case
  (handled by `add_content`'s existing `attr_docs` branch) untouched. Overriding
  `add_content` would have required re-implementing/guarding that branch.

- **Keeping the `get_class_members` signature.** The now-unused `objpath` /
  `analyzer` parameters are retained for backward compatibility (the function is
  imported and used elsewhere as a semi-public helper); only the body changed.

- **Scope.** The change deliberately targets `AttributeDocumenter` (data
  attributes), since comment-based docs only apply to data attributes. Inherited
  methods and properties already work because their documentation lives on the
  object's `__doc__` and is resolved by normal attribute inheritance. This also
  incidentally fixes the closely-related inherited *instance* attribute case
  (issue #6415) noted in the thread, with no change to module-level
  `DataDocumenter` behavior.

- **`class_` of an inherited class attribute stays `None`.** An inherited
  class-level attribute discovered via `dir()` keeps `class_ = None`, which is
  what the non-`:inherited-members:` path relies on to exclude it
  (`m.class_ == self.object` is `False`). Only its docstring is filled in, so the
  with/without `:inherited-members:` filtering behavior is preserved.
