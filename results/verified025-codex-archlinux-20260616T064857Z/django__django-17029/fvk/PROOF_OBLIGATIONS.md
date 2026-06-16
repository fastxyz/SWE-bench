# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: `clear_cache()` empties every app-registry cache in scope

- Claim source: `CLEAR-CACHE-READY`, `CLEAR-CACHE-NOT-READY`.
- Precondition: any prior registry version, any prior `get_models()` cache
  version, and any prior `get_swappable_settings_name()` cache version.
- Required postcondition: `modelsCacheVersion == -1` and
  `swappableCacheVersion == -1`.
- Evidence: E-001 through E-004.
- V1 discharge: `clear_cache()` calls both `self.get_models.cache_clear()` and
  `self.get_swappable_settings_name.cache_clear()`.
- Finding trace: F-001, F-002.

## PO-002: Swappable lookup after `clear_cache()` uses current registry state

- Claim source: `LOOKUP-AFTER-CLEAR-READY`,
  `LOOKUP-AFTER-CLEAR-NOT-READY`.
- Precondition: any prior stale swappable cache version.
- Required postcondition: after `clear_cache(); get_swappable_settings_name`,
  `lookupObservedVersion == registryVersion`.
- Evidence: E-001 through E-004.
- V1 discharge: clearing the swappable cache forces lookup recomputation from
  the current registry state.
- Finding trace: F-001.

## PO-003: Existing ready-gated model `_meta` cache expiry behavior is preserved

- Claim source: `CLEAR-CACHE-READY`, `CLEAR-CACHE-NOT-READY`.
- Precondition: `ready` is either true or false.
- Required postcondition: if `ready` is true, model meta caches are expired; if
  `ready` is false, the model meta expiry action is skipped.
- Evidence: E-006.
- V1 discharge: the new cache-clear call is before the existing `if self.ready`
  branch and does not alter the branch.
- Finding trace: no code bug; compatibility frame.

## PO-004: Mutation paths that call `clear_cache()` inherit the fix

- Claim source: `MUTATE-CLEAR-LOOKUP-READY`,
  `MUTATE-CLEAR-LOOKUP-NOT-READY`.
- Precondition: an app-registry mutation advances the abstract registry
  version and calls `clear_cache()`.
- Required postcondition: the next swappable lookup observes the advanced
  registry version.
- Evidence: E-005 and E-008.
- V1 discharge: mutation paths already call `clear_cache()`, and V1 repairs the
  centralized invalidation operation.
- Finding trace: F-001.

## PO-005: Public API and caller compatibility are preserved

- Claim source: `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Precondition: existing in-repository callers invoke `clear_cache()` and
  `get_swappable_settings_name(to_string)` with their existing signatures.
- Required postcondition: no caller update is needed; return-value shape is
  unchanged.
- Evidence: E-007, E-008.
- V1 discharge: V1 adds one internal method call and changes no signature,
  return value, or dispatch argument.
- Finding trace: F-003.
