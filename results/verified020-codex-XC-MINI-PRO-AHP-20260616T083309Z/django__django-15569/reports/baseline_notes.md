# Baseline Notes

## Root Cause

`RegisterLookupMixin.get_lookups()` is cached with `functools.lru_cache()` and
returns lookup mappings derived from the class hierarchy. `register_lookup()`
updates `class_lookups` and then calls `_clear_cached_lookups()`, which clears
the cached lookup mappings for the target class and its subclasses.

`_unregister_lookup()` also mutates `class_lookups`, but it only deleted the
lookup entry. Any previously cached lookup mapping could therefore continue to
include the removed lookup until another cache-clearing operation happened. This
can leak temporary test lookup registrations across later checks, especially
when the `django.test.utils.register_lookup()` context manager unregisters a
lookup after code has already populated the lookup cache.

## Changed Files

`repo/django/db/models/query_utils.py`

Added a call to `cls._clear_cached_lookups()` after
`RegisterLookupMixin._unregister_lookup()` deletes the lookup from
`cls.class_lookups`. This makes unregistering symmetric with registration and
ensures cached lookup mappings reflect the current class lookup registry.

## Assumptions and Alternatives

The fix assumes that unregistering a lookup should invalidate the same cache
scope as registering one: the class whose lookup registry changed and all of
its subclasses. That matches the existing `_clear_cached_lookups()` helper and
preserves behavior for inherited lookup resolution.

I considered clearing only `cls.get_lookups`, but rejected it because subclass
lookup caches can include lookups inherited from `cls`; leaving those caches
intact would still allow stale lookup results.

I considered changing the test helper context manager to clear caches after
calling `_unregister_lookup()`, but rejected it because `_unregister_lookup()`
is the method that mutates the lookup registry and should keep the cache
consistent for all callers, including other internal cleanup paths.
