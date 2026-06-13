# Control notes — V2 review outcome for django__django-13344

## Decision: V1 stands unchanged (no code edits in V2)

A systematic, skeptical re-review of the V1 fix found no problems requiring code
changes. Every aspect checked traced back to a confirming finding in
`review/FINDINGS.md`. The rationale for keeping each part of V1 is below.

### Keep: `self._async_check()` added to `SecurityMiddleware.__init__`
Traced to **F1** (fixes the reported coroutine leak: the SecurityMiddleware
instance now reports `iscoroutinefunction() == True`, so the preceding middleware
gets an async-wrapped handler and awaits it) and **F2** (it was one of exactly
four broken middlewares). Placement after the existing `self.get_response =
get_response` is the minimal change; per **F7** it matches `SessionMiddleware`.

### Keep: `self._async_check()` added to `UpdateCacheMiddleware.__init__`
Traced to **F1**/**F2**. Same mechanism and rationale as SecurityMiddleware.

### Keep: `self._async_check()` added to `FetchFromCacheMiddleware.__init__`
Traced to **F1**/**F2**. Same mechanism and rationale.

### Keep: `self._async_check()` added to `CacheMiddleware.__init__`
Traced to **F1**/**F2** for correctness, **F4** for the safe placement (it reads
only `self.get_response`, which is set on the preceding line, so running it before
the remaining attribute assignments is fine), and **F3** for confirming no
regression in the `cache_page` / `decorator_from_middleware` usage (that path
calls `process_*` methods directly and never consults the instance marker, so the
added marker is inert there).

### Keep: `SessionMiddleware` and `RedirectFallbackMiddleware` untouched
Traced to **F2**: they already invoke `_async_check()` (directly, and via
`super().__init__()` respectively), so no change was needed.

### Rejected alternative: refactor to `super().__init__(get_response)`
Traced to **F6**: it would double-fire the deprecation warning (the subclasses
already call `_get_response_none_deprecation`) and, for `CacheMiddleware`, MRO
would route into `UpdateCacheMiddleware.__init__` and run the wrong
initialization. The `_async_check()` approach is minimal and MRO-safe, so V1's
approach was retained.

### Rejected alternative: re-order `_async_check()` to the end in all four
Considered for cosmetic uniformity. Rejected because the chosen rule
("`_async_check()` immediately follows the `self.get_response = …` assignment")
is already uniform and functionally identical across all four (**F4**, **F7**);
reordering would add churn without benefit.

### Rejected alternative: harden the marker mechanism / change handler code
Traced to **F8**: the only consumer of the instance-level `_is_coroutine` marker
for middleware is `convert_exception_to_response`. The defect was purely that the
four instances failed to set the marker; the documented contract is to set it in
`__init__` via `_async_check()`. Changing the handler/exception code or adding a
lazier detection mechanism would be a broader architectural change beyond the
issue's scope and was rejected.

### No-action item
Traced to **F9**: the `RemovedInDjango40Warning` comments show only the future
`__init__` signature, not its body, so they remain accurate. No edit made.

## Boundary/regression confidence
Per **F5**: the deprecated `get_response=None` path and pure-WSGI operation are
unaffected (the marker is simply not set when `get_response` is non-async), and
the single-middleware ASGI case continues to work (now more correctly). No test
files were modified, per the task constraints.

## Summary
V1 was confirmed correct and complete by the review; no source changes were made
in V2. The fix remains the four `self._async_check()` additions in
`django/middleware/security.py` and `django/middleware/cache.py`.
