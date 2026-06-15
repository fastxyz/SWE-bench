# FVK Spec: InheritDocstrings Property Docstrings

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were executed.

## Target

`repo/astropy/utils/misc.py::InheritDocstrings.__init__`

Observable under audit: during class creation, public overriding members with
missing docstrings should inherit the docstring from the first overridden member
found through normal base-class resolution.

## Public Intent Ledger

| ID | Source | Quoted Evidence | Semantic Obligation | Status |
|---|---|---|---|---|
| E1 | prompt issue | "InheritDocstrings metaclass doesn't work for properties" | A subclass `property` that overrides a documented inherited property and has no docstring must receive the inherited docstring. | Encoded by PO-01 and claim `dataDescriptor` inheritance. |
| E2 | prompt issue | "`inspect.isfunction` ... returns `False` for properties" | The eligibility predicate must not be limited to functions. | Encoded by PO-01. |
| E3 | public hint | "should work with `inspect.isdatadescriptor`" | Data descriptors are the intended abstraction for properties in this fix. | Encoded by PO-01 and PO-03. |
| E4 | existing docstring | "methods ... automatically have their docstrings filled in" | Existing method inheritance must still work. | Encoded by PO-02. |
| E5 | existing docstring | "first class in the bases list ... same way as methods are normally resolved" | The first inherited member found by MRO wins; later bases do not overwrite it. | Encoded by PO-04. |
| E6 | prompt discussion | "if I redefine it without setting the docstring" | Only missing subclass docstrings are filled; explicit subclass docstrings are preserved. | Encoded by PO-05. |
| E7 | public API shape | `InheritDocstrings` is exported and used as a metaclass across Astropy. | Do not change the metaclass signature or its public/private member filter. | Encoded by PO-05, PO-06, and PO-08. |
| E8 | FVK finding | V1 broadened eligibility to all data descriptors and assigned `__doc__` unconditionally. | A descriptor with read-only `__doc__` must not abort class creation. | Encoded by PO-07 and fixed in V2. |

## Intent-Only Specification

For each `(key, member)` in the class namespace:

1. If `key` is public under the existing predicate, `member.__doc__ is None`,
   and `member` is a Python function or data descriptor, then the member is
   eligible for inherited-docstring filling.
2. For an eligible member, the docstring copied is the `__doc__` of the first
   base-class member with the same key according to Python MRO.
3. Existing function behavior remains unchanged.
4. Data descriptors are handled without invoking descriptor getters while
   searching for the inherited descriptor object.
5. Members with explicit docstrings, private non-dunder names, non-functions,
   non-data-descriptors, or no inherited member remain unchanged.
6. If an otherwise eligible descriptor cannot accept assignment to `__doc__`,
   class creation continues and that descriptor is left unchanged.

## Formal Spec English

The K-style claims in `fvk/inherit-docstrings-spec.k` state:

- `PROPERTY-INHERITS`: a public data descriptor with `noneDoc` and writable
  docs becomes a descriptor with the inherited `doc("base doc")`.
- `METHOD-PRESERVED`: a public function with `noneDoc` and writable docs still
  receives the inherited method doc.
- `EXPLICIT-DOC-FRAME`: a public data descriptor that already has `doc("sub doc")`
  keeps it.
- `INELIGIBLE-FRAME`: a non-eligible member remains unchanged even when a base
  member has a docstring.
- `PRIVATE-FRAME`: a private non-dunder data descriptor remains unchanged even
  when a base member has a docstring.
- `READONLY-DOC-FRAME`: a data descriptor whose doc cannot be assigned remains
  unchanged instead of raising.
- `DESCRIPTOR-STATIC-LOOKUP`: data-descriptor inheritance uses static lookup.

## Spec Audit

All formal-English claims map to public intent entries E1-E8. No claim is based
only on V1 behavior. The only implementation-derived detail is the exact
read-only-doc handling in E8; it is justified as a compatibility guard after
the audit identified a V1 regression risk caused by widening the eligible
member set from functions to all data descriptors.

## Compatibility Audit

- Public signature: unchanged (`__init__(cls, name, bases, dct)`).
- Public export: unchanged (`InheritDocstrings` remains in `__all__`).
- Public/private filter: unchanged.
- Method-doc inheritance path: preserved by keeping dynamic `getattr` lookup for
  function members.
- Descriptor path: new support for data descriptors; static lookup avoids
  invoking descriptor `__get__` during class creation.
- Tests: no test files changed.
