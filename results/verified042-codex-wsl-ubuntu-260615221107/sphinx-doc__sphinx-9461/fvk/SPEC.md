# FVK Specification: autodoc classmethod-property support

Status: constructed from public intent and source inspection; not machine-checked.

## Scope

The audited behavior is Sphinx autodoc member discovery and rendering for class
members declared as `@classmethod` over `@property`.

Primary source units:

- `repo/sphinx/ext/autodoc/importer.py`
  - `get_class_member(subject, name, attrgetter)`
  - `get_object_members(subject, objpath, attrgetter, analyzer=None)`
  - `get_class_members(subject, objpath, attrgetter)`
- `repo/sphinx/ext/autodoc/__init__.py`
  - `PropertyDocumenter.import_object()`

## Intent-Only Obligations

I1. Class members decorated with both `@classmethod` and `@property` must be
documented.

Evidence: `benchmark/PROBLEM.md`: "Methods decorated with @classmethod and
@property do not get documented" and "Expected behavior: Methods that are
decorated with both `@classmethod` and `@property` should be documented
appropriately."

I2. The docstring to document is the wrapped property/getter docstring, not the
docstring of the computed return value.

Evidence: `benchmark/PROBLEM.md`: "type(BaseClass.baseclass_class_property)
returns the type of the returned object ... Sphinx doesn't really have a chance
to extract the docstring."

I3. Ordinary `@property` behavior must be preserved.

Evidence: `benchmark/PROBLEM.md`: "regular `@property` decorated methods get
documented just fine."

I4. Abstract class properties must remain abstract in generated documentation.

Evidence: the problem lists missing `metaclass_abstract_class_property`,
`baseclass_abstract_class_property`, and `subclass_abstract_class_property`.

I5. The fix must support autodoc and autosummary class-member generation.

Evidence: the issue lists "Sphinx extensions: sphinx.ext.autodoc,
sphinx.ext.autosummary."

I6. The fix must not change public attrgetter extension compatibility.

Evidence: Sphinx exposes `add_autodoc_attrgetter()` and autodoc member lookup is
defined around a caller-supplied attrgetter.

## Public Evidence Ledger

| ID | Source | Quoted evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | issue | "Methods decorated with @classmethod and @property do not get documented." | Such members must be included by member discovery/filtering. | Encoded by PO-1, PO-4. |
| E2 | issue | "`type(BaseClass.baseclass_class_property)` returns the type of the returned object" | Normal `getattr(cls, name)` is the failing mechanism and must be bypassed for this wrapper shape. | Encoded by PO-1. |
| E3 | issue | "Sphinx doesn't really have a chance to extract the docstring." | The object passed to docstring extraction must be the wrapped `property`. | Encoded by PO-5, PO-6. |
| E4 | issue | "regular `@property` decorated methods get documented just fine." | Existing ordinary-property behavior is a frame condition. | Encoded by PO-2. |
| E5 | issue | Abstract class-property names are explicitly listed. | Abstract metadata must remain observable. | Encoded by PO-6. |
| E6 | issue | "sphinx.ext.autodoc, sphinx.ext.autosummary" | Both class-member consumers must see the corrected member object. | Encoded by PO-4. |
| E7 | code/API | `add_autodoc_attrgetter()` registers custom attrgetters. | Fallback behavior must continue through the active attrgetter. | Encoded by PO-2, PO-3. |

## Formal Model

This is a reduced mini-Python model of class member lookup. It abstracts away
HTML output and focuses on the observable that matters for the issue: which
object autodoc passes to classification, filtering, and property rendering.

Definitions:

- `MRO(subject)` is the finite class MRO in Python order.
- `raw(cls, name)` is the direct dictionary value `cls.__dict__[name]`, or
  `absent`.
- `first_raw(subject, name)` is the first non-absent `raw(cls, name)` in
  `MRO(subject)`.
- `cmp(raw)` holds when `raw` is a `classmethod` object whose `__func__` is a
  `property`.
- `wrapped(raw)` is `raw.__func__`.
- `AG(subject, name)` is the pre-existing active attrgetter result.

Contract C1:

For all in-domain class-like `subject`, member names `name`, and getattr-like
`attrgetter`, if `first_raw(subject, name) = R` and `cmp(R)`, then
`get_class_member(subject, name, attrgetter) = wrapped(R)`.

Contract C2:

For all in-domain inputs, if the first class in the MRO that defines `name`
does not define it as `classmethod(property(...))`, then
`get_class_member(subject, name, attrgetter) = AG(subject, name)`.

Contract C3:

If a subclass defines `name`, the subclass raw value is decisive. Inherited
`classmethod(property(...))` descriptors must not override a subclass's direct
non-wrapper definition.

Contract C4:

Every class-member value retrieved by `get_object_members()` and
`get_class_members()` must use `get_class_member()` on class paths, including
the enum-specific path. This keeps the classification object consistent across
the generic and class-specific enumeration helpers.

Contract C5:

After `PropertyDocumenter.import_object()` succeeds for a class parent,
`self.object` must be the result of `get_class_member(self.parent,
self.object_name, self.get_attr)`. Therefore direct `autoproperty` rendering and
member-generated property rendering use the same corrected object.

Contract C6:

When `self.object` is the wrapped property, existing Sphinx property handling
must provide:

- `PropertyDocumenter.can_document_member(...) == True`;
- docstring extraction from `property.__doc__`;
- abstract metadata from `property.__isabstractmethod__`;
- return type extraction from `property.fget` when type hints are enabled.

## Adequacy Audit

The formal contracts cover the issue's intended behavior because they force the
only object substitution needed to turn the failing computed-value path into the
existing successful property path. They are not stronger than the issue:
ordinary non-wrapper members continue to use the active attrgetter result, and
subclass overrides keep Python MRO precedence.

The contracts do not specify metaclass attributes of a documented class unless
they appear through the audited class-member paths. The public issue names the
metaclass class's own class properties and ordinary classes' own class
properties, not inherited metaclass attributes on unrelated classes.

## Compatibility Audit

Changed public surface:

- `sphinx.ext.autodoc.importer.get_class_member()` is new internal helper
  surface, imported into `sphinx.ext.autodoc.__init__`.
- Existing signatures of `get_class_members()`, `get_object_members()`, and
  `PropertyDocumenter.import_object()` are unchanged.

Compatibility obligations:

- Existing attrgetter extensions still observe final fallback lookups because
  non-wrapper members return `attrgetter(subject, name)`.
- Raw class dictionary lookup uses the supplied attrgetter only for `__dict__`;
  if that access fails or lacks the name, the helper continues to the next MRO
  class or falls back to the original attrgetter.
- Autosummary class-content generation calls `sphinx.ext.autodoc.get_class_members()`
  and therefore receives the corrected property object.

No public callsites or overrides require signature changes.
