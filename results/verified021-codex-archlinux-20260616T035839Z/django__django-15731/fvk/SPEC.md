# FVK Specification: Manager QuerySet Method Signatures

Status: constructed, not machine-checked. No tests, Python snippets, or K tooling
were executed.

## Scope

The audited unit is `BaseManager._get_queryset_methods()` in
`repo/django/db/models/manager.py`, especially the nested `create_method()`
factory that copies eligible `QuerySet` methods onto generated manager classes.

The observable behavior under specification is introspection metadata on copied
manager methods. Database behavior, SQL generation, and queryset evaluation are
outside this specification except for the forwarding frame condition.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I-001 | `benchmark/PROBLEM.md` | "`inspect.signature` returns incorrect signature information when used on queryset methods" | A copied manager method must expose the corresponding queryset method signature through `inspect.signature()` when accessed as a bound manager method. | Encoded in S-001 and PO-001. |
| I-002 | `benchmark/PROBLEM.md` | `Person.objects.bulk_create` actual `(*args, **kwargs)`, expected queryset-specific parameters | The generic forwarding signature is the reported bug; the expected signature is the source queryset method's public parameters after binding removes `self`. | Encoded in S-001. |
| I-003 | `benchmark/PROBLEM.md` | "complete metadata is not copied" | The copied method must preserve wrapper metadata beyond `__name__` and `__doc__`, especially metadata that lets introspection follow the original callable. | Encoded in S-002 and PO-002. |
| I-004 | `benchmark/PROBLEM.md` | "The fix is to use `functools.wraps`" | A wrapper-based repair is public-intent evidence, not merely an implementation preference. | Encoded in S-002. |
| I-005 | `repo/django/db/models/manager.py` | `_get_queryset_methods()` skips existing manager methods and queryset-only/private methods | The fix must preserve method-selection behavior for generated managers. | Encoded as frame condition S-003. |
| I-006 | `repo/django/db/models/manager.py` | `manager_method()` calls `getattr(self.get_queryset(), name)(*args, **kwargs)` | Runtime call forwarding must remain unchanged for copied methods. | Encoded as frame condition S-004. |
| I-007 | `repo/django/db/models/query.py` | Current `QuerySet.bulk_create()` has additional keyword parameters beyond the issue example | The spec must not hard-code the issue's old example signature; it must track the current queryset method signature generically. | Encoded in S-001 and Finding F-002. |

## Intended Contract

S-001: For every queryset class `Q`, manager superclass `C`, and function
`method` copied by `_get_queryset_methods(C, Q)`, the bound manager method
`manager.method` must have an `inspect.signature()` equal to the bound signature
of the original queryset method. In particular, if the queryset method signature
is `(self, p1, ..., pn)`, then the bound manager method signature is
`(p1, ..., pn)`.

S-002: Each copied manager proxy must preserve the original queryset method as
wrapper metadata, including `__wrapped__`, and preserve the metadata that
`functools.wraps()` assigns by default.

S-003: The set of methods copied onto the manager remains exactly the set
selected before the fix: methods not already present on the manager class, and
not excluded by `queryset_only=True` or by private-name default exclusion.

S-004: Calling a copied manager method with positional and keyword arguments
still forwards to `getattr(self.get_queryset(), name)(*args, **kwargs)`.

## Domain and Preconditions

- `method` is a Python function discovered by `inspect.getmembers()` with
  `predicate=inspect.isfunction`.
- `method` is eligible under the existing queryset-only/private filtering rules.
- `inspect.signature()` uses Python's documented wrapper-following behavior and
  bound-method handling: follow `__wrapped__`, then remove the already-bound
  leading receiver parameter.
- Partial correctness only: the spec does not prove that the forwarded queryset
  operation terminates or succeeds.

## Abstract Formal Model

This model is intentionally small: it represents only functions, wrapper
metadata, bound methods, and signature extraction.
The supporting constructed K-style files are `fvk/mini-python-signature.k` and
`fvk/manager-signature-spec.k`.

```k
// Constructed specification sketch, not executed.
// Sorts:
//   Func(name, params, wrapped)
//   Bound(receiver, func)
//   Params = [Param*]
//   wrapped = none | some(Func)
//
// Python/functools abstraction:
//   wraps(original)(proxy) rewrites proxy.wrapped to some(original) and copies
//   default wrapper metadata.
//
// inspect.signature abstraction:
//   signature(Bound(receiver, Func(_, params, some(original))))
//       => drop_bound_receiver(signature(Func(original)))
//   signature(Bound(receiver, Func(_, params, none)))
//       => drop_bound_receiver(params)
//
// V1 create_method abstraction:
//   create_method(name, method)
//       => wraps(method)(Func(method.name, [self, *args, **kwargs], none))
//
// Main claim:
//   eligible(method) =>
//   signature(Bound(manager, create_method(name, method)))
//       == drop_bound_receiver(method.params)
```

## Adequacy Check

- The formal model states the public intent at the same abstraction level as the
  issue: introspection-visible signatures on copied manager methods.
- It does not prove SQL/database effects because the issue does not require a
  behavioral change there, and S-004 explicitly frames call forwarding as
  unchanged.
- The model is generic in the queryset method's parameter list, which makes it
  adequate for both the issue's displayed `bulk_create()` signature and the
  longer `bulk_create()` signature present in this checkout.
