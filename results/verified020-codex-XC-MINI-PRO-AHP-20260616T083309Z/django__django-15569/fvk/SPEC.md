# SPEC

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Target

Source unit under audit: `repo/django/db/models/query_utils.py`,
`RegisterLookupMixin._unregister_lookup()`.

Candidate V1 behavior:

1. Resolve `lookup_name` from the argument or `lookup.lookup_name`.
2. Delete `cls.class_lookups[lookup_name]`.
3. Call `cls._clear_cached_lookups()`, which clears `get_lookups()` caches for
   `cls` and every subclass found through `subclasses(cls)`.

## Intent Spec

`RegisterLookupMixin.get_lookups()` is an `lru_cache`-backed view of lookup
registries from the class MRO. Any operation that mutates a class lookup
registry must invalidate cached lookup views that can depend on that registry.

For `_unregister_lookup(cls, lookup, lookup_name)` on its intended domain:

- Precondition: `lookup_name` identifies an existing entry in
  `cls.class_lookups`; if omitted, it is read from `lookup.lookup_name`.
- Postcondition: the entry is removed from `cls.class_lookups`.
- Cache postcondition: cached lookup maps for `cls` and every subclass of
  `cls` are invalidated before any later `get_lookups()` result may be reused.
- Recompute postcondition: a later `get_lookups()` call on `cls` or a subclass
  computes from the current MRO registries, so the removed lookup is absent
  unless another still-registered class in that MRO supplies that lookup name.
- Frame condition: lookup entries other than `lookup_name`, non-descendant class
  caches, method signatures, and caller protocols are unchanged.

Thread safety is explicitly outside the method contract because the docstring
says the method is for tests only and not thread-safe.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt | "`RegisterLookupMixin._unregister_lookup()` should clear the lookup cache." | `_unregister_lookup()` must invalidate the lookup cache after unregistering. | Encoded in K claim `UNREGISTER-CLEARS-DESCENDANT-CACHES`; satisfied by V1. |
| E-002 | prompt | "the cache is not cleared, which should be done, as it is done in `register_lookup`" | Unregister cache scope should mirror `register_lookup()` cache scope. | Encoded as descendant-inclusive cache clearing. |
| E-003 | source | `get_lookups()` is decorated with `functools.lru_cache(maxsize=None)`. | Cached lookup maps can survive registry mutation unless explicitly cleared. | Encoded in model as a `<cache>` cell. |
| E-004 | source | `_clear_cached_lookups()` iterates `for subclass in subclasses(cls): subclass.get_lookups.cache_clear()`. | A registry mutation on `cls` can affect subclass cached lookup maps. | Encoded with an inclusive descendant set. |
| E-005 | source | `register_lookup()` mutates `cls.class_lookups` and then calls `_clear_cached_lookups()`. | Mutation and invalidation must happen together. | Used as matching behavior for unregister. |
| E-006 | source | `_unregister_lookup()` docstring: "For use in tests only as it's not thread-safe." | Do not introduce a thread-safety guarantee or broad public API behavior. | Domain/frame condition. |
| E-007 | source/callsite | `django.test.utils.register_lookup()` unregisters temporary lookups in `finally`. | Temporary lookup cleanup must not leave a stale cached lookup visible to later code. | Covered by recompute postcondition. |
| E-008 | source/public test evidence | `tests/model_fields/test_jsonfield.py` manually calls `_clear_cached_lookups()` after `_unregister_lookup()`. | Existing users needed explicit cache clearing after unregister; method should own that invariant. | Supports V1; test cleanup is outside this task. |

## Formal Model Summary

The K model in `mini-lookup-cache.k` abstracts Python execution to the state
the issue manipulates:

- `<registry>` maps `(class, lookup_name)` to present or absent.
- `<cache>` maps a class to either a cached lookup view or `uncached`.
- `<descendants>` maps a class to the inclusive set of classes whose
  `get_lookups()` cache can include lookup entries inherited from that class.

The transition `unregisterLookup(C, N)` removes `(C, N)` from `<registry>` and
clears caches for all classes in `<descendants>[C]`. This model preserves the
defect axis: V0 and V1 differ exactly by whether descendant cache entries remain
cached after the registry mutation.

## Claim Summary

`UNREGISTER-CLEARS-DESCENDANT-CACHES`:

For any class `C`, lookup name `N`, registry `REG`, cache `CACHE`, and inclusive
descendant set `DESC`, if `(C, N)` is registered and `DESC` contains `C` plus
every subclass whose lookup cache may depend on `C`, executing
`unregisterLookup(C, N)` reaches a state where:

- `(C, N)` is absent from the registry,
- every cache entry for a class in `DESC` is marked `uncached`,
- no cache outside `DESC` is changed by the clear operation.

`GET-LOOKUPS-RECOMPUTES-AFTER-UNREGISTER`:

For every descendant `D` in `DESC`, a later `getLookups(D)` cannot reuse the old
cached view. It must compute from current MRO registry entries, which excludes
the removed `(C, N)` entry unless another still-present MRO entry supplies `N`.

## Adequacy Decision

The formal claims match the prompt-derived intent. They are not copied from a
legacy behavior: the legacy/V0 state is explicitly represented as the failing
case where `<registry>` changes but `<cache>` remains cached. V1 changes that
state transition by clearing the dependent caches.

