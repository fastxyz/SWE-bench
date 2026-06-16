# Iteration Guidance

## Decision

Keep V1 unchanged.

## Rationale

- F-001 identified the operative defect: the swappable-settings cache survived
  `clear_cache()`. PO-001 and PO-002 are discharged by the V1 line
  `self.get_swappable_settings_name.cache_clear()`.
- F-002 and PO-001 found no additional `functools.cache` method in `Apps` that
  remains outside `clear_cache()`.
- PO-003 confirms V1 does not change the existing ready-gated model `_meta`
  cache expiry behavior.
- PO-004 confirms repairing `clear_cache()` is the correct central fix because
  registry mutation paths already call it.
- F-003 and PO-005 show no API compatibility change requiring further edits.

## Rejected follow-up edits

- Do not remove the `get_swappable_settings_name()` cache. Its source docstring
  says the cache exists for migration performance, and the issue asks for
  invalidation, not de-caching.
- Do not duplicate swappable-cache invalidation at every mutation callsite.
  `clear_cache()` is the existing central invalidation point, and PO-004 covers
  mutation paths through it.
- Do not move the new cache-clear line under `if self.ready`. PO-002 must hold
  independently of ready state.

## Suggested future checks

When an execution environment is available, a focused public regression test
should exercise a stale `get_swappable_settings_name()` cache before
`clear_cache()` and verify that a subsequent lookup recomputes from the current
registry state. Test deletion is not recommended unless the K proof is
machine-checked.
