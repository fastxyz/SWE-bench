# PROOF_OBLIGATIONS

Status: constructed, not machine-checked.

## O-001: Intended Domain

For `_unregister_lookup(cls, lookup, lookup_name)`, the proof assumes
`lookup_name` resolves to a key currently present in `cls.class_lookups`.

Justification: `_unregister_lookup()` is a test-only cleanup helper and uses
`del`, so absence is an existing `KeyError` precondition rather than an
idempotent no-op contract. Supported by FINDINGS F-004.

## O-002: Registry Deletion

After successful `_unregister_lookup(cls, lookup, lookup_name)`,
`cls.class_lookups[lookup_name]` is absent.

Justification: direct source statement `del cls.class_lookups[lookup_name]`.
Covered by K claim `UNREGISTER-CLEARS-DESCENDANT-CACHES`.

## O-003: Descendant-Inclusive Cache Invalidation

After the registry deletion, every `get_lookups()` cache for `cls` and each
subclass reachable through `subclasses(cls)` is cleared.

Justification: source call `cls._clear_cached_lookups()` and helper behavior.
Required by prompt evidence that unregister should clear the lookup cache and by
FINDINGS F-001/F-002.

## O-004: Recompute Uses Current Registry

After invalidation, a later `get_lookups()` call on `cls` or a dependent
subclass recomputes the merged MRO lookup dictionary from current
`class_lookups`, not from stale cached data.

Justification: `get_lookups()` is an `lru_cache` function. Clearing the cache
removes the old entry; the next call re-executes the merge over the MRO.

## O-005: Frame Conditions

The fix must not alter:

- lookup name resolution from `lookup.lookup_name`,
- `KeyError` behavior for absent entries,
- method signature or return value,
- non-cache registry entries unrelated to the deleted key.

Justification: prompt only requires cache clearing after unregister; source
callers rely on the existing helper shape. Supported by FINDINGS F-004/F-005.

## O-006: Subclass Cache Scope Is Necessary

Cache clearing must include subclasses, not only `cls`, because subclass
`get_lookups()` results may include lookup entries inherited from `cls`.

Justification: `_clear_cached_lookups()` is already used by `register_lookup()`
and iterates `subclasses(cls)`. Supported by FINDINGS F-002.

## O-007: Compatibility With Callers

Existing internal callers of `_unregister_lookup()` must continue to work
without adding caller-side cache cleanup.

Justification: `django.test.utils.register_lookup()` performs temporary
registration cleanup in `finally`; `django.contrib.postgres.apps` unregisters
lookups when the app is removed from `INSTALLED_APPS`; one public test manually
called `_clear_cached_lookups()` as a workaround. Supported by FINDINGS F-003
and F-005.

## O-008: Honesty Gate

The proof is constructed only. K commands are emitted in `PROOF.md`, but not
executed. No tests or project code were run.

Justification: task constraint forbids tests, Python, and K tooling.

