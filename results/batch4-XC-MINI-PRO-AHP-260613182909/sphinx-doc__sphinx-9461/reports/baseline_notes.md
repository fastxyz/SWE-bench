# Baseline notes — sphinx-doc__sphinx-9461

## Issue

Since Python 3.9, a method can be decorated with both `@classmethod` and
`@property`:

```python
class A:
    @classmethod
    @property
    def f(cls):
        """Some class property."""
        return "property"
```

Sphinx's autodoc silently fails to document such members (regular `@property`
members work fine). In the reporter's demo the following were *not* documented
at all: `MetaClass.metaclass_class_property`,
`MetaClass.metaclass_abstract_class_property`,
`BaseClass.baseclass_class_property`,
`BaseClass.baseclass_abstract_class_property`,
`SubClass.subclass_class_property`,
`SubClass.subclass_abstract_class_property`.

## Root cause

A `@classmethod @property` is stored in the class `__dict__` as a `classmethod`
object whose `__func__` is the underlying `property`. Unlike a plain property,
when this descriptor is read through attribute access — `getattr(cls, name)` —
Python 3.9+ invokes the wrapped property's getter and returns the **computed
value** (e.g. the string `"property"`) rather than the `property` descriptor
itself. (`type(BaseClass.baseclass_class_property)` is the type of the returned
object, not `property`.)

This breaks autodoc in two compounding ways:

1. **Member collection (`get_class_members` in `sphinx/ext/autodoc/importer.py`):**
   the member value recorded for the attribute is the computed value, not the
   property. So the descriptor — and therefore the docstring — is lost.

2. **`Documenter.filter_members` (`sphinx/ext/autodoc/__init__.py`):** it fetches
   the docstring with `getdoc(member, …)`. For the computed value (say a `str`)
   this yields `str.__doc__`, which then equals `member.__class__.__doc__`, so
   the code at the "inherited docstring" guard nulls it out
   (`has_doc = False`). With no docstring and no `:undoc-members:`, the member is
   dropped *before* any documenter is even chosen. That is why the members were
   "not documented at all".

Even if it had survived filtering, `PropertyDocumenter.can_document_member` only
recognised `inspect.isproperty(member)`, which is false for the computed value,
and there was no way to render a property as a classmethod.

## Changes

### `sphinx/ext/autodoc/importer.py`
- Import `isproperty` from `sphinx.util.inspect`.
- In `get_class_members`, when a class-dict entry is a `classmethod` whose
  `__func__` is a property, record the underlying **property** as the member
  value instead of the getter's computed result. This is the key fix: with the
  property in hand, `filter_members` finds the real docstring (member is kept)
  and the `PropertyDocumenter` is selected.

### `sphinx/ext/autodoc/__init__.py` — `PropertyDocumenter`
- `can_document_member`: in addition to plain properties, recognise a
  classmethod-wrapped property by inspecting `parent.object.__dict__`
  (`isinstance(obj, classmethod) and inspect.isproperty(obj.__func__)`). This is
  a robustness fallback for cases where the member value reaching the documenter
  is not already the unwrapped property.
- `import_object` (new override): `super().import_object()` resolves the
  attribute through `getattr`, so for a classmethod-property `self.object` is the
  computed value. Recover the property from `self.parent.__dict__[name].__func__`
  and remember the fact in `self.isclassmethod`. A plain property leaves
  `self.isclassmethod = False`.
- `add_directive_header`: emit `:classmethod:` when `self.isclassmethod` is set
  (after the existing `:abstractmethod:` handling, matching the option ordering
  used by methods).

### `sphinx/domains/python.py` — `PyProperty`
- Add the `classmethod` flag to `option_spec` so the `:classmethod:` option
  produced by autodoc is accepted.
- `get_signature_prefix` now prepends `class` (yielding `class property`, and
  `class abstract property` when combined with `:abstractmethod:`), mirroring the
  existing short-form `abstract` keyword. The existing `abstractmethod` branch is
  left untouched so the plain `abstract property` output is unchanged.

### Documentation / changelog
- `doc/usage/restructuredtext/domains.rst`: document the new `:classmethod:`
  option on the `py:property` directive.
- `CHANGES`: add a "Features added" entry under 4.2.0.

## Assumptions and rejected alternatives

- **Why fix `get_class_members` rather than only the documenter.** I traced the
  control flow and confirmed `filter_members` runs *before* documenter
  selection and discards the member when its (computed-value) docstring looks
  inherited. Fixing only `PropertyDocumenter` would therefore have no effect —
  the member never reaches it. Surfacing the property in `get_class_members` is
  the minimal change that addresses the real root cause.
- **Storing the property vs. the raw `classmethod`.** I store the unwrapped
  `property` because `property.__doc__` reliably exposes the getter's docstring,
  whereas a `classmethod` object's `__doc__` is not dependably forwarded on
  Python 3.9. Storing the property also lets the existing `isproperty(member)`
  checks and documenter-priority logic work unchanged (PropertyDocumenter's
  priority already outranks AttributeDocumenter).
- **`import_object` still re-derives the property.** `Documenter.import_object`
  independently re-fetches the object via the import/`getattr` chain (it does not
  reuse the value collected by `get_class_members`), so it again sees the
  computed value. Hence the dedicated override that recovers
  `…__dict__[name].__func__`.
- **Scope: own-class members.** The unwrap in `get_class_members` keys off the
  class's own `__dict__` (`name in obj_dict`), and `import_object` looks in
  `self.parent.__dict__`. This documents each class's *own* classmethod-
  properties — exactly the members listed in the report (each shown under its
  defining class). Inherited classmethod-properties are filtered out by default
  (`get_object_members` keeps only `m.class_ == self.object`) just like other
  inherited members, so no MRO walking was added, keeping the change minimal.
- **Prefix wording.** Chose `class property` (short form, consistent with the
  pre-existing `abstract property`) over the longer `classmethod property`. The
  new `classmethod` branch is appended after the existing `abstractmethod`
  branch, leaving the plain `abstract property` output unchanged and yielding
  `class abstract property` for the combined case. The directive option itself is
  named `:classmethod:` to match what autodoc emits and the option name already
  used by `py:method`.
- **Python < 3.9.** The detection is harmless on older versions: if such a
  construct exists it is simply documented as a property. No version guard was
  added, consistent with the surrounding code style.
