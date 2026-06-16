# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `django__django-17029`: the
app-registry cache invalidation behavior of `Apps.clear_cache()` and its
interaction with `Apps.get_swappable_settings_name()`.

The scope is intentionally narrower than all of Django. It covers the changed
method, the cached method named by the issue, and app-registry mutation paths
that centralize invalidation through `clear_cache()`.

## Public intent ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The core obligations are:

- `clear_cache()` must clear all app-registry internal caches affected by
  registry mutation.
- `get_swappable_settings_name()` is one of those caches because it is
  decorated with `functools.cache` and computes from the current model list.
- Callers that mutate the app registry and then call `clear_cache()` must not
  leave stale swappable-settings lookup results behind.
- Existing ready-gated model `_meta` cache expiry behavior must be preserved.
- No public API or caller protocol may change.

## Formal model

The mini semantics in `fvk/mini-python-cache.k` represents:

- `registryVersion`: the current app-registry state.
- `modelsCacheVersion`: the version held by `get_models()`'s cache, or `-1`
  when empty.
- `swappableCacheVersion`: the version held by
  `get_swappable_settings_name()`'s cache, or `-1` when empty.
- `lookupObservedVersion`: the registry version used by the last modeled
  swappable lookup.
- `ready` and `metaCachesExpired`: the existing ready-gated model `_meta`
  cache expiry branch.

This abstraction is property-complete for the reported defect: a stale
swappable cache and a correctly cleared swappable cache produce different
`lookupObservedVersion` values.

## Claims

`fvk/apps-registry-spec.k` states six claims:

- `CLEAR-CACHE-READY`: `clear_cache` empties both registry caches and expires
  model meta caches when ready.
- `CLEAR-CACHE-NOT-READY`: `clear_cache` empties both registry caches and does
  not expire model meta caches when not ready.
- `LOOKUP-AFTER-CLEAR-READY`: a swappable lookup after `clear_cache` observes
  the current registry state when ready.
- `LOOKUP-AFTER-CLEAR-NOT-READY`: the same lookup property holds when not
  ready.
- `MUTATE-CLEAR-LOOKUP-READY`: after a modeled registry mutation while ready,
  `clear_cache` forces the next swappable lookup to observe the mutated
  registry state.
- `MUTATE-CLEAR-LOOKUP-NOT-READY`: the same mutation-clear-lookup property
  holds when not ready.

## Expected machine-check commands

These commands are written for later verification and were not executed:

```sh
kompile fvk/mini-python-cache.k --backend haskell
kast --backend haskell fvk/apps-registry-spec.k
kprove fvk/apps-registry-spec.k
```

Expected `kprove` result after installing/running K: `#Top` for all claims.
