# INTENT_SPEC

Intent-only obligations from public evidence.

1. `_unregister_lookup()` must clear the lookup cache after removing a lookup.
   Source: issue statement.
2. The cache-clearing behavior should correspond to `register_lookup()`.
   Source: issue statement comparing unregister to register.
3. Because `get_lookups()` is cached, any registry mutation must make later
   lookup queries observe the current registry rather than stale cached data.
   Source: source name and `lru_cache` use.
4. Because `_clear_cached_lookups()` clears `cls` and subclasses, inherited
   lookup cache entries are in scope.
   Source: helper implementation and register path.
5. `_unregister_lookup()` remains a test-only, non-thread-safe cleanup helper.
   Source: method docstring.
6. The existing method signature and successful-delete behavior must be
   preserved; only cache invalidation is added.
   Source: issue scope and public/internal callsites.

Observed V0 behavior to check, not intended behavior: the registry entry is
deleted but cached lookup maps may remain populated.

