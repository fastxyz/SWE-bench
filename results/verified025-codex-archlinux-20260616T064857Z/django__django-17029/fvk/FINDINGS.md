# FVK Findings

Status: constructed, not machine-checked. Findings are based on public issue
intent, static source inspection, and the constructed proof obligations.

## F-001: Pre-fix cache invalidation was incomplete

- Classification: code bug fixed by V1.
- Evidence: `benchmark/PROBLEM.md` reports that `Apps.clear_cache()` did not
  clear `get_swappable_settings_name()`'s cache, despite the method's contract
  to clear internal app-registry caches.
- Concrete state: registry version changes from `R` to `R + 1`, but
  `swappableCacheVersion` remains `R`; a subsequent swappable lookup observes
  stale version `R` instead of `R + 1`.
- Expected: after `clear_cache()`, the swappable cache is empty, so the next
  lookup observes the current registry version.
- V1 status: resolved by `self.get_swappable_settings_name.cache_clear()` in
  `repo/django/apps/registry.py`.
- Proof obligations: PO-001, PO-002, PO-004.

## F-002: No additional app-registry cached method was found in scope

- Classification: audit result supporting V1 unchanged.
- Evidence: static source inspection of `repo/django/apps/registry.py` shows
  two `functools.cache` methods in `Apps`: `get_models()` and
  `get_swappable_settings_name()`.
- Expected: `clear_cache()` clears both app-registry cached methods.
- V1 status: resolved; V1 clears both caches.
- Proof obligations: PO-001.

## F-003: Compatibility risk is low and no source edit is required

- Classification: compatibility finding, no code bug.
- Evidence: V1 does not change the signature, return value, or caller protocol
  of `clear_cache()` or `get_swappable_settings_name()`. Static search found no
  in-repository override of `get_swappable_settings_name()`.
- Expected: existing callers continue to call `clear_cache()` and
  `get_swappable_settings_name(to_string)` unchanged.
- V1 status: confirmed unchanged.
- Proof obligations: PO-005.

## F-004: Proof is constructed, not machine-checked

- Classification: proof honesty gate.
- Evidence: task instructions prohibit running tests, Python, or K tooling.
- Expected: record exact commands and reason about expected outcomes without
  executing them.
- V1 status: no code blocker; do not remove tests based on this constructed
  proof alone.
- Proof obligations: all obligations are constructed/static only.

## Proof-derived findings from `/verify`

No new code defect was surfaced by the proof construction. The only behavior
that prevents the pre-fix obligations from discharging is the missing
swappable-settings cache clear, which V1 supplies.
