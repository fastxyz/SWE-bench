# Formal Spec English

The K files are `fvk/mini-python-cache.k` and
`fvk/apps-registry-spec.k`. They model the issue-relevant part of
`Apps.clear_cache()` as a state machine.

## Claims

1. `CLEAR-CACHE-READY`: For any registry version and any prior model-list and
   swappable-settings cache versions, running `clear_cache` when `ready` is
   true terminates with both cache versions empty, preserves the registry
   version, and marks model meta caches expired.

2. `CLEAR-CACHE-NOT-READY`: For any registry version and any prior model-list
   and swappable-settings cache versions, running `clear_cache` when `ready` is
   false terminates with both cache versions empty, preserves the registry
   version, and does not expire model meta caches.

3. `LOOKUP-AFTER-CLEAR-READY`: If a swappable-settings lookup is performed
   after `clear_cache` when the registry is ready, the lookup observes the
   current registry version and repopulates the swappable cache from that
   current version.

4. `LOOKUP-AFTER-CLEAR-NOT-READY`: The same current-registry lookup property
   holds when `ready` is false; the only difference is that model meta cache
   expiry remains skipped.

5. `MUTATE-CLEAR-LOOKUP-READY`: If a registry mutation advances the registry
   version while `ready` is true, then calls `clear_cache`, then performs a
   swappable-settings lookup, the lookup observes the advanced registry version
   rather than any stale cache version that existed before the mutation.

6. `MUTATE-CLEAR-LOOKUP-NOT-READY`: The same mutation-clear-lookup property
   holds when `ready` is false; the only difference is that model meta cache
   expiry remains skipped.

## Abstraction notes

- A cache is represented by an integer version. `-1` means empty. Any other
  value means the cache can return data computed from that registry version.
- This abstraction distinguishes the pre-fix failing state from the fixed
  state: with a stale swappable cache version `SC != current registry version`,
  omitting `clear_swappable_settings_name_cache` lets the lookup observe `SC`;
  V1 clears it to `-1`, forcing recomputation from the current registry version.
