# FVK Notes

## Decision summary

V1 stands unchanged. The FVK audit found the same root cause as the baseline
pass and did not surface a justified additional source edit.

## Trace to findings and proof obligations

- Keeping the V1 line
  `self.get_swappable_settings_name.cache_clear()` is justified by F-001 and
  PO-001/PO-002: `clear_cache()` must empty the swappable-settings cache so a
  later lookup cannot observe a stale registry version.
- Not adding callsite-specific cache clearing is justified by F-001 and PO-004:
  registry mutation methods already centralize invalidation through
  `clear_cache()`, so the correct repair is in `clear_cache()` itself.
- Not changing `get_swappable_settings_name()`'s caching behavior is justified
  by F-001 and PO-002: the proof obligation requires recomputation after
  `clear_cache()`, not removal of the intentional migration-performance cache.
- Not changing the ready-gated `_meta` cache expiry branch is justified by
  PO-003: V1 adds the swappable cache clear before the existing `if self.ready`
  branch and preserves the branch behavior.
- Not making compatibility edits is justified by F-003 and PO-005: no signature,
  return shape, public call protocol, or in-repository override required a
  change.
- Not removing or editing tests is justified by F-004 and the benchmark
  instructions; it applies to all PO-001 through PO-005 because those
  obligations are constructed, not machine-checked, and test files are
  fixed/hidden for this task.

## Code status

No additional source edits were made during the FVK phase. The only production
code change remains the V1 addition in `repo/django/apps/registry.py`.

## Verification status

The FVK proof artifacts record the K commands that should be run in a future
environment, but no tests, Python, or K tooling were executed in this session.
