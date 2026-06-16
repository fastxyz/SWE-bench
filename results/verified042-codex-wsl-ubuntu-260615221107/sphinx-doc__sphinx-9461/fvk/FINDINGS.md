# FVK Findings

Status: constructed from public intent and static source inspection; no tests,
Python, or K tooling were run.

## F1: V1 left one class-enumeration branch outside the helper invariant

Classification: code coverage gap, fixed in V2.

Evidence:

- `SPEC.md` C4 requires every class-member value retrieved by
  `get_object_members()` and `get_class_members()` to use `get_class_member()`.
- V1 already used `get_class_member()` in the normal `dir(subject)` loops and
  in `get_class_members()`' enum branch.
- V1 still used `safe_getattr(subject, name)` in `get_object_members()`' enum
  branch.

Concrete input:

An enum-like class subject with a directly defined
`classmethod(property(...))` member that flows through the deprecated generic
`get_object_members()` helper.

Observed in V1:

That enum-specific branch could evaluate the descriptor and return the computed
value.

Expected:

All class-member lookup paths should preserve the wrapped property object for
the wrapper shape described in the issue.

Resolution:

Changed that branch to call `get_class_member(subject, name, safe_getattr)`.

## F2: Core V1 helper design satisfies the issue's main failure mode

Classification: confirmed behavior.

Evidence:

- `SPEC.md` E1-E3 identify normal class attribute access as the failing
  mechanism.
- `PROOF_OBLIGATIONS.md` PO-1 and PO-5 require discovery and rendering to use
  the wrapped property rather than the computed value.

Concrete input:

```python
class A:
    @classmethod
    @property
    def f(cls):
        """Some class property."""
        return "property"
```

Observed in V1/V2 by static reasoning:

`get_class_member(A, "f", attrgetter)` reads `A.__dict__["f"]`, recognizes a
`classmethod` wrapping a `property`, and returns the wrapped property without
calling `attrgetter(A, "f")`.

Expected:

Autodoc member classification and docstring extraction see a property object,
matching existing ordinary-property handling.

Resolution:

No further change beyond keeping the V1 helper.

## F3: Override precedence is preserved

Classification: confirmed behavior.

Evidence:

- `SPEC.md` C3 requires the first defining class in the MRO to decide the raw
  descriptor.
- `PROOF_OBLIGATIONS.md` PO-3 discharges this by the helper's break after the
  first raw definition that is not a classmethod-property.

Concrete input:

A base class defines `f` as `classmethod(property(...))`, and a subclass defines
`f` as an ordinary method, ordinary property, or data attribute.

Observed in V1/V2 by static reasoning:

The helper reaches the subclass dictionary first. Because the subclass value is
not the wrapper shape, it breaks and returns the original attrgetter result for
the subclass member.

Expected:

Subclass overrides must not be replaced by inherited descriptors.

Resolution:

No source change needed.

## F4: Abstract class properties are covered by existing property rendering

Classification: confirmed behavior with existing Sphinx dependency.

Evidence:

- The issue explicitly lists abstract class-property members.
- `PropertyDocumenter.add_directive_header()` already checks
  `inspect.isabstractmethod(self.object)`.
- The helper makes `self.object` the wrapped `property`, and Python property
  objects expose abstractness through `__isabstractmethod__` when their getter
  is abstract.

Concrete input:

`@classmethod @property @abstractmethod def f(cls): ...`

Observed in V1/V2 by static reasoning:

The property object reaches `PropertyDocumenter`; existing logic can emit
`:abstractmethod:`.

Expected:

The abstract flag should be documented the same way ordinary abstract
properties are documented.

Resolution:

No source change needed.

## F5: Autosummary class generation is covered; module scanning is not changed

Classification: scoped confirmation and residual risk.

Evidence:

- The issue lists `sphinx.ext.autosummary`.
- Autosummary generated class content calls
  `sphinx.ext.autodoc.get_class_members(obj, [qualname], safe_getattr)`, which
  now uses `get_class_member()`.
- `ModuleScanner.scan()` still uses `safe_getattr()` directly, but that scanner
  is module-member scanning rather than the class-member generation path needed
  to document the class properties named in the issue.

Concrete input:

Autosummary rendering of class members for a class containing
`@classmethod @property`.

Observed in V1/V2 by static reasoning:

The class-content path receives the wrapped property object.

Expected:

Autosummary class pages include the class property through the same corrected
member object as autodoc.

Resolution:

No source change to module scanning; record as residual risk outside the
reported class-member path.

## F6: Runtime verification intentionally absent

Classification: verification limitation.

Evidence:

The task forbids running tests, Python, or K tooling.

Observed:

No commands that execute project code, tests, Python snippets, `kompile`, or
`kprove` were run.

Expected:

Proof artifacts must be labeled constructed, not machine-checked.

Resolution:

`PROOF.md` includes commands to run later and expected outcomes, but does not
claim they were executed.
