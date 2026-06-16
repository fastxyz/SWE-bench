# PUBLIC_EVIDENCE_LEDGER

| ID | Source | Quoted or Minimal Evidence | Semantic Obligation |
| --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md` | "`RegisterLookupMixin._unregister_lookup()` should clear the lookup cache." | Cache invalidation is required after unregister. |
| E-002 | `benchmark/PROBLEM.md` | "as it is done in `register_lookup`" | Use the same invalidation scope as registration unless contradicted. |
| E-003 | `repo/django/db/models/query_utils.py` | `@functools.lru_cache(maxsize=None)` on `get_lookups()` | Cached lookup maps can be stale after registry mutation. |
| E-004 | `repo/django/db/models/query_utils.py` | `_clear_cached_lookups()` loops over `subclasses(cls)` | Dependent subclass caches are part of the required invalidation scope. |
| E-005 | `repo/django/db/models/query_utils.py` | `register_lookup()` mutates `class_lookups` then calls `_clear_cached_lookups()` | Registry mutation and cache invalidation are paired. |
| E-006 | `repo/django/db/models/query_utils.py` | `_unregister_lookup()` docstring says "For use in tests only" and "not thread-safe" | Do not claim thread safety or broaden the public contract. |
| E-007 | `repo/django/test/utils.py` | Context manager unregisters lookups in `finally` | Temporary test lookups must be cleaned from both registry and cache. |
| E-008 | `repo/tests/model_fields/test_jsonfield.py` | Test manually calls `_clear_cached_lookups()` after `_unregister_lookup()` | Existing test code documents the missing method-owned invalidation. |

