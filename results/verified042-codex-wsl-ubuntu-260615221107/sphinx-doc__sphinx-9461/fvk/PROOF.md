# FVK Constructed Proof

Status: constructed, not machine-checked. The task forbids running tests,
Python, `kompile`, or `kprove`.

## Summary

The V2 source satisfies the specification in `SPEC.md` after one audit-driven
improvement: the enum branch in `get_object_members()` now uses
`get_class_member()` like the other class-member enumeration branches.

## Proof Of PO-1

For a member whose first raw MRO definition is `classmethod(property(...))`,
`get_class_member()` iterates over `getmro(subject)` and obtains
`attrgetter(cls, "__dict__", {})[name]`. On the first defining class, this
lookup succeeds with the raw classmethod object. The branch
`isclassmethod(value) and isproperty(value.__func__)` is true, so the helper
returns `value.__func__`.

Because the return happens before the final `return attrgetter(subject, name)`,
the descriptor on `subject.name` is not invoked. This discharges the issue's
core requirement: autodoc sees the property object rather than the computed
property value.

## Proof Of PO-2

If the first defining class has a raw value that is not
`classmethod(property(...))`, the helper executes the `else: break` path. It
then reaches the final `return attrgetter(subject, name)`. This is the same
lookup behavior the pre-fix code used for non-wrapper members.

If no MRO class dictionary contains `name`, or raw dictionary access raises
`AttributeError`, `KeyError`, or `TypeError`, the loop continues until it is
exhausted and then returns `attrgetter(subject, name)`. This preserves ordinary
methods, ordinary properties, descriptors, data attributes, and custom attrgetter
behavior outside the wrapper shape.

## Proof Of PO-3

The helper scans `getmro(subject)` in order and stops at the first class whose
dictionary contains `name`. Therefore a subclass definition is inspected before
any base definition. If the subclass definition is not the wrapper shape, the
helper breaks and falls back to `attrgetter(subject, name)`, so an inherited
base class property cannot override the subclass member.

## Proof Of PO-4

Static inspection of `repo/sphinx/ext/autodoc/importer.py` after V2 shows the
four audited class-member retrieval sites call `get_class_member()`:

- `get_object_members()` enum branch;
- `get_object_members()` `dir(subject)` branch;
- `get_class_members()` enum branch;
- `get_class_members()` `dir(subject)` branch.

Thus member classification for autodoc and autosummary class generation receives
the wrapped property object for the issue's wrapper shape.

## Proof Of PO-5

`PropertyDocumenter.import_object()` first delegates to the existing import
logic. If that import fails, it returns the failure result unchanged. If it
succeeds and `self.parent` is a class, it assigns:

```python
self.object = get_class_member(self.parent, self.object_name, self.get_attr)
```

Therefore direct `autoproperty` rendering and member-generated rendering both
use the same corrected object. Non-class parents keep the existing import
object, preserving behavior outside class-level properties.

## Proof Of PO-6

Once `self.object` is the wrapped property, no new rendering machinery is
needed:

- `PropertyDocumenter.can_document_member()` already recognizes
  `inspect.isproperty(member)`;
- `Documenter.get_doc()` delegates to `getdoc(self.object, ...)`, and property
  objects expose their getter docstring as `__doc__`;
- `PropertyDocumenter.add_directive_header()` already emits
  `:abstractmethod:` when `inspect.isabstractmethod(self.object)` is true;
- the same method already reads `self.object.fget` to extract a return type.

So the new lookup behavior reconnects `@classmethod @property` to the existing
ordinary-property documentation path.

## Constructed Machine-Check Commands

These commands are not run in this session. The referenced `.k` files are
constructed reduced-semantics sketches for the lookup proof obligations.

```sh
kompile fvk/mini-python-autodoc.k --backend haskell
kast --backend haskell fvk/autodoc-class-property-spec.k
kprove fvk/autodoc-class-property-spec.k
```

Expected outcome after completing the reduced encoding: `kprove` returns `#Top`
for PO-1 through PO-5. PO-6 depends on Python/Sphinx descriptor facts modeled as
environment lemmas because this benchmark does not include executable K
semantics for Python's full descriptor protocol.

## Test Recommendations

No tests were added or modified because the task forbids editing tests.

Tests to add or keep in a normal development environment:

- direct `@classmethod @property` on a class is documented as a property with
  its getter docstring;
- abstract `@classmethod @property` emits `:abstractmethod:`;
- inherited class properties are documented when inherited members are enabled;
- subclass overrides are not replaced by inherited class properties;
- autosummary class generation sees the property member;
- enum class-member enumeration follows the same helper path.

No test should be removed based on this constructed proof until the K claims are
actually machine-checked and the ordinary Sphinx test suite is run.
