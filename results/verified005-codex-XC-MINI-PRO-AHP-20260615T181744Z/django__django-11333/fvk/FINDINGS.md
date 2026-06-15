# FVK Findings

Constructed, not machine-checked.

## F-001: Duplicate default resolver construction in V0

Input sequence: call `get_resolver(None)` before request handling sets a
thread-local URLconf, then call `get_resolver(settings.ROOT_URLCONF)` after
request handling has called `set_urlconf(settings.ROOT_URLCONF)`.

Observed in V0 by code inspection: because `functools.lru_cache()` keyed the
public function before its body normalized `None`, these calls occupied
different cache entries and could construct different `URLResolver` instances.

Expected from public intent: both calls mean the same default root URLconf and
should reuse one cached resolver.

Status: fixed by V1. `get_resolver()` now normalizes `None` before entering the
cached helper. Discharged by PO-1 and PO-2.

## F-002: Cache clearing must follow the moved cache

Input sequence: call `get_resolver(None)`, call `clear_url_caches()`, then call
`get_resolver(None)` again.

Potential regression introduced by moving the cache: `clear_url_caches()` calls
`get_resolver.cache_clear()`, so a private helper cache would remain stale if
that public cache-control hook no longer cleared it.

Expected from public/internal compatibility: the second post-clear call should
construct a fresh resolver rather than reuse the pre-clear helper entry.

Status: fixed by V1. `get_resolver.cache_clear` forwards to
`_get_cached_resolver.cache_clear`. Discharged by PO-4.

## F-003: Explicit non-default URLconfs must remain distinct

Input sequence: call `get_resolver("project.urls")`, then call
`get_resolver("tenant.urls")`, with `settings.ROOT_URLCONF` set to some other
root.

Potential over-fix: a normalization rule that collapsed too much could reuse
the default resolver for explicit non-default URLconfs.

Expected from public intent and existing callsites: only omitted/`None` default
forms collapse to `settings.ROOT_URLCONF`; explicit non-default URLconfs remain
independent.

Status: V1 preserves this. Discharged by PO-3.

## F-004: Hashability domain boundary

Input sequence: call `get_resolver(None)` when `settings.ROOT_URLCONF` is an
unhashable object such as a list.

Observed boundary: the V1 helper cache keys by normalized URLconf, so the proof
domain requires a hashable effective URLconf.

Expected from public docs: `ROOT_URLCONF` is a string import path, and public
tests use strings or hashable class/module-like URLconf objects. Explicit
unhashable arguments were already incompatible with the public LRU-cached
`get_resolver(urlconf)` path.

Status: not a source bug for this issue. Recorded as a precondition/domain
boundary in PO-6.

## F-005: Proof honesty gate

The K model and claims were constructed but not machine-checked. No
`kompile`, `kast`, `kprove`, Python, or Django test command was run.

Status: proof remains a constructed audit. Test removal is not recommended.
