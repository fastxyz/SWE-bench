# Intent Specification

Status: constructed from public issue text and in-repository source comments,
not from hidden tests or upstream fixes.

## Required behavior

1. `Apps.clear_cache()` must clear all internal caches owned by the app
   registry that are affected by methods altering the app registry.

2. Because `Apps.get_swappable_settings_name()` is cached and its result is
   computed from the current installed model set, `Apps.clear_cache()` must
   invalidate that cache in the same cache-clearing operation that already
   invalidates `Apps.get_models()`.

3. After an app-registry mutation that calls `clear_cache()`, the next
   `get_swappable_settings_name(to_string)` call must be based on the current
   registry state, not on a value cached before the mutation.

4. The existing `clear_cache()` behavior that expires per-model `_meta` caches
   only when the registry is ready must be preserved.

5. The public method signatures, return values, and caller protocol for
   `Apps.clear_cache()` and `Apps.get_swappable_settings_name()` must not
   change.

## Domain assumptions

- The proof concerns normal app-registry state transitions where registry
  mutation methods call `clear_cache()`.
- `functools.cache.cache_clear()` empties the decorated function's cache.
- The formal proof is partial correctness over the modeled operations; it does
  not prove Python descriptor internals or thread-scheduling behavior.
