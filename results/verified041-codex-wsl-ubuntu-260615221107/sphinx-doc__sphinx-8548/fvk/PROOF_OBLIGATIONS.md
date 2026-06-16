# FVK Proof Obligations

All obligations are partial-correctness obligations over the static source model.
They are constructed, not machine-checked.

## PO-1: Parent module and namespace lookup

For every class `cls` in `getmro(subject)`, `_get_class_attr_docs(cls, analyzer)`
must:

- identify `cls.__module__` and `cls.__qualname__`;
- reuse the current analyzer when `analyzer.modname == cls.__module__`;
- otherwise use `ModuleAnalyzer.for_module(cls.__module__)`;
- return only `attr_docs[(cls.__qualname__, name)]` entries.

Evidence: E2, E3.

Code: `repo/sphinx/ext/autodoc/importer.py:255`.

## PO-2: MRO owner rule

For runtime and annotation members, the comment attached to a member must come
from the class that Python MRO says defines that member. If that owner has no
comment, later bases must not contribute a comment for the same name.

Evidence: E6.

Code: `repo/sphinx/ext/autodoc/importer.py:275`,
`repo/sphinx/ext/autodoc/importer.py:294`, and
`repo/sphinx/ext/autodoc/importer.py:342`.

## PO-3: Member collection carries inherited attribute comments

For `ClassDocumenter.get_object_members()` with `:inherited-members:`, inherited
runtime attributes must be returned as `ObjectMember(..., docstring=<base
comment>)` when the defining class has an attribute comment.

Evidence: E1, E4.

Code: `repo/sphinx/ext/autodoc/importer.py:366` and
`repo/sphinx/ext/autodoc/__init__.py:1587`.

## PO-4: Explicit autoattribute inherited-comment content

For explicit `autoattribute:: Subclass.attr`, if the subclass namespace has no
direct comment but the MRO owner has one, `AttributeDocumenter.add_content()` must
emit that comment and suppress fallback object/value docstrings.

Evidence: E2, E5.

Code: `repo/sphinx/ext/autodoc/__init__.py:2164` and
`repo/sphinx/ext/autodoc/__init__.py:2362`.

## PO-5: Filter treats injected attribute docs as attribute documentation

If `ClassDocumenter` injects an `ObjectMember.docstring`, `filter_members()` must
set `has_doc` and `isattr` so the member is selected without `:undoc-members:`
and documented through the attribute path.

Evidence: E1, E4.

Code: `repo/sphinx/ext/autodoc/__init__.py:715`.

## PO-6: Compatibility frame condition

The fix must not add a new required virtual method call to all `Documenter`
subclasses. The inherited-comment fallback must be limited to attribute
documenters.

Evidence: I5 and F-001.

Code: V2 leaves `Documenter.add_content()` in its original direct-lookup shape
and implements fallback at `repo/sphinx/ext/autodoc/__init__.py:2362`.

## PO-7: Instance-only synthesis frame condition

The fix must not newly synthesize inherited `self.attr` comment-only members for
subclasses. Direct/current class instance comment synthesis remains unchanged.

Evidence: E7 and F-003.

Code: `get_class_members()` only adds missing comment-derived members when
`cls == subject`, at `repo/sphinx/ext/autodoc/importer.py:373`.

## PO-8: Honesty gate

All proof and test-redundancy statements must be marked constructed, not
machine-checked, because no tests, Python, or K tooling may be run.

Evidence: task no-exec rule and FVK verify honesty gate.

Artifacts: `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md`.

