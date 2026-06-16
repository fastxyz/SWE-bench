# FVK Specification

Status: constructed from public intent and static source inspection; not
machine-checked.

## Scope

The audited behavior is Sphinx autodoc's handling of comment-derived docstrings
for inherited class/data attributes. The relevant units are:

- `get_class_members()` and helper functions in
  `repo/sphinx/ext/autodoc/importer.py`.
- `ClassDocumenter.get_object_members()`, `Documenter.filter_members()`,
  `UninitializedInstanceAttributeMixin.get_attribute_comment()`, and
  `AttributeDocumenter.add_content()` in
  `repo/sphinx/ext/autodoc/__init__.py`.

This specification intentionally covers inherited runtime/annotation attributes
and explicit `autoattribute` for such attributes. It does not require
`:inherited-members:` to synthesize inherited instance-only `self.attr` comments
that have no runtime/annotation member on the subclass; the public issue text
distinguishes that as a related but separate problem.

## Intent Spec

I1. If a base class defines a documented data attribute and a subclass inherits
that attribute, `.. autoclass:: Subclass` with `:inherited-members:` must include
the inherited attribute as a documented attribute.

I2. Attribute comment lookup must not be limited to the subclass namespace
`(Subclass, attr)`. It must also consider the namespace and module of the base
class that defines the inherited attribute.

I3. Explicit `.. autoattribute:: Subclass.attr` must render the inherited
attribute comment when `attr` is inherited from a documented base attribute.

I4. Python MRO ownership is the winner rule. If a subclass or earlier base
defines `attr`, a later base class's comment must not be attached to that member.

I5. Existing direct attribute comments, value rendering, annotations, and
documenter extension compatibility should be preserved except where the public
issue requires the inherited-attribute behavior.

## Public Evidence Ledger

E1. Source: `benchmark/PROBLEM.md`.
Quote: "autodoc inherited-members won't work for inherited attributes (data
members)."
Obligation: inherited documented data attributes must be selected for
`:inherited-members:`.
Status: encoded by PO-1, PO-3, and K claim `collectMembers`.

E2. Source: `benchmark/PROBLEM.md`.
Quote: "autodoc searches for a cached docstring using (namespace, attrname) as
search-key, but doesn't check for baseclass-namespace."
Obligation: lookup must search the defining base-class namespace, not only the
subclass namespace.
Status: encoded by PO-1, PO-4, and K claim `attributeContent`.

E3. Source: public hint in `benchmark/PROBLEM.md`.
Quote: "parser for attributes' doc strings parses only one module. It should
also parses modules of all parent classes and combine everything."
Obligation: parent-class modules must be considered when their source is
available.
Status: encoded by `_get_class_attr_docs()` using `ModuleAnalyzer.for_module()`
for non-current modules.

E4. Source: public example in `benchmark/PROBLEM.md`.
Quote: "`Base.ham` attribute is not present in the docs for `Inherited`.
However, the `Base.eggs` inherited method is displayed."
Obligation: the desired observable is `Inherited.ham` present in the generated
member documentation with the base comment.
Status: encoded by PO-3 and PO-5.

E5. Source: public comment in `benchmark/PROBLEM.md`.
Quote: "even using autoattribute does not work."
Obligation: explicit `autoattribute` must also use inherited attribute comments.
Status: encoded by PO-4 and `AttributeDocumenter.add_content()`.

E6. Source: Python default-domain convention.
Quote: Python class attribute resolution follows MRO.
Obligation: comments attach to the class that actually defines the member, and
overrides block fallback to older bases.
Status: encoded by PO-2.

E7. Source: public discussion in `benchmark/PROBLEM.md`.
Quote: "inherited-instance attributes are not supported yet (filed as #6415
now)."
Obligation: do not expand this fix into synthesis of inherited instance-only
attributes unless separately specified.
Status: encoded as a frame condition and residual non-obligation.

## Formal Spec English

FE1. For any class `Subject`, attribute `name`, and MRO class `Owner`, if Python
MRO says `Owner` defines `name` and `Owner`'s module analyzer has a comment for
`(Owner.__qualname__, name)`, then `get_class_members(Subject, ...)` records
that member with `class_ == Owner` and `docstring == Owner`'s comment.

FE2. If a name is documented only on a later base that does not own the attribute
selected by Python MRO, the lookup returns no inherited comment for that member.

FE3. For `ClassDocumenter` with `:inherited-members:`, any ObjectMember carrying
an injected attribute docstring is considered documented and attribute-like, so
the member survives filtering without requiring `:undoc-members:`.

FE4. For explicit `autoattribute` on `Subclass.attr`, if the current subclass
namespace lacks an attribute comment and the MRO owner has one, the generated
attribute content uses the owner comment and suppresses fallback value docstrings.

FE5. Direct subclass comments continue to use the existing
`Documenter.add_content()` path. The inherited fallback is local to
`AttributeDocumenter`, so unrelated documenters and base `Documenter` subclasses
do not gain a new virtual hook requirement.

## K Formal Core

The formal sketch files are:

- `fvk/mini-autodoc.k`
- `fvk/autodoc-inherited-attrs-spec.k`

They model the minimal observable state: MRO order, owner relation, attribute
comment cache, collected members, member filtering as an attribute, and
autoattribute content. The claims correspond to FE1-FE4 and include provenance
comments.

Exact commands to machine-check later, not run in this session:

```sh
kompile fvk/mini-autodoc.k --backend haskell
kast --backend haskell fvk/autodoc-inherited-attrs-spec.k
kprove fvk/autodoc-inherited-attrs-spec.k
```

Expected outcome after a real K formalization pass: `kprove` returns `#Top`.
This session did not run K tooling.

## Spec Audit

FE1 passes. It directly implements E1-E3 and the default MRO owner rule E6.

FE2 passes. It is required by E6; inheriting a comment from a non-owner base
would document the wrong attribute.

FE3 passes. It is required by E1 and E4; without this, the inherited attribute
can be collected but still filtered as undocumented.

FE4 passes. It is required by E2 and E5; `autoattribute` is a separate observable
path from `autoclass :inherited-members:`.

FE5 passes. It is required by E5's narrow behavior and by the compatibility frame
condition I5; V1's broader base `Documenter` hook failed this audit and was
revised.

## Public Compatibility Audit

Changed public-ish symbols:

- Added private helper `_get_class_attr_docs()` in `autodoc.importer`: no public
  caller impact.
- Added public helper `get_class_attr_doc()` in `autodoc.importer`: additive only.
- Changed internal member owner assignment in `get_class_members()`: preserves the
  returned mapping shape and `ClassAttribute` shape.
- Kept `UninitializedInstanceAttributeMixin.get_attribute_comment(parent)`
  callable with the original `parent` argument.
- Did not add a new base `Documenter` virtual hook in V2. V1 did; that was
  removed after the compatibility audit.

No in-repo public callsites or subclass overrides require changes. Third-party
documenters that subclass `Documenter` are not asked to implement any new method.

