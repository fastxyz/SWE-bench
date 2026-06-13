# Code review — V1 fix for django__django-13344

V1 added `self._async_check()` immediately after `self.get_response = get_response`
in four `__init__` methods:

- `django/middleware/security.py` — `SecurityMiddleware`
- `django/middleware/cache.py` — `UpdateCacheMiddleware`, `FetchFromCacheMiddleware`,
  `CacheMiddleware`

Below are the numbered review findings.

---

## F1 — Correctness against the issue: CONFIRMED CORRECT

The issue: under ASGI, with ≥2 middlewares, the *first* middleware's
`process_response()` receives an un-awaited `coroutine`.

`asyncio.iscoroutinefunction(obj)` returns `True` for a *callable object* only if
`getattr(obj, '_is_coroutine', None)` is the asyncio sentinel. `MiddlewareMixin`
sets that sentinel in `_async_check()` when `get_response` is async. The four
broken middlewares overrode `__init__` and never called `_async_check()`, so
their instances reported `False` from `iscoroutinefunction()` even when handed an
async `get_response`.

End-to-end trace of `MIDDLEWARE = [DummyMiddleware, SecurityMiddleware]` under
ASGI **with the fix** (chain built bottom-up in `BaseHandler.load_middleware`):

1. `SecurityMiddleware(handler)` is created with an async `handler`; `_async_check()`
   now sets `_is_coroutine`.
2. `convert_exception_to_response(security_instance)` (exception.py:34) now sees
   `iscoroutinefunction(security_instance) == True` and returns the **async**
   `inner`. (Before the fix it returned the **sync** `inner` — the defect.)
3. That async `inner` becomes `DummyMiddleware.get_response`, so
   `DummyMiddleware.__call__` detects an async `get_response`, routes to
   `__acall__`, and **awaits** it.
4. `await`-ing resolves `SecurityMiddleware.__acall__` to an `HttpResponse` before
   `DummyMiddleware.process_response(request, response)` is invoked.

So the first middleware now receives an `HttpResponse`, not a coroutine. The fix
directly resolves the reported symptom.

Consistency with the public hint ("one middleware → HttpResponse; two → coroutine
on the first"): with a single middleware the top-level `get_response_async` awaits
the chain result, so the stray coroutine was resolved before any
`process_response` ran. With two, the outer middleware consumed the coroutine
synchronously and handed it to its own `process_response`. The fix addresses the
two-plus case and leaves the single-middleware case working (see F5).

## F2 — Completeness: all affected middlewares covered: CONFIRMED

Exhaustive search of `repo/django/` for middleware classes and `__init__`
overrides shows exactly five middlewares override `__init__`:

- `SecurityMiddleware`, `UpdateCacheMiddleware`, `FetchFromCacheMiddleware`,
  `CacheMiddleware` — all four were missing `_async_check()` and are now fixed.
- `SessionMiddleware` (`contrib/sessions/middleware.py:18`) — already calls
  `self._async_check()`. Untouched (correct).
- `RedirectFallbackMiddleware` (`contrib/redirects/middleware.py:21`) — already
  calls `super().__init__(get_response)`, which runs `_async_check()`. Untouched
  (correct).

Every other middleware (`CommonMiddleware`, `CsrfViewMiddleware`,
`LocaleMiddleware`, `GZipMiddleware`, `ConditionalGetMiddleware`,
`XFrameOptionsMiddleware`, `MessageMiddleware`, `AuthenticationMiddleware`,
`RemoteUserMiddleware`, `BrokenLinkEmailsMiddleware`, etc.) does not override
`__init__` and therefore inherits `MiddlewareMixin.__init__`, which already calls
`_async_check()`. No in-tree middleware is missed.

## F3 — No regression in the `cache_page` / `decorator_from_middleware` path: CONFIRMED

`CacheMiddleware` is also instantiated as a view decorator via
`make_middleware_decorator` (`django/utils/decorators.py:117`):
`middleware = middleware_class(view_func, ...)`. With the fix, if `view_func` is a
coroutine function, `_async_check()` will set `_is_coroutine` on the
`CacheMiddleware` instance.

This is harmless: the decorator's `_wrapped_view` calls the middleware's
`process_request` / `process_view` / `process_response` methods **directly** and
never calls the instance via `__call__`, nor does it ever pass the instance to
`asyncio.iscoroutinefunction()`. The only consumer of the instance-level
`_is_coroutine` marker is `convert_exception_to_response` in the handler chain
(see F8), which the decorator path does not use. Therefore the marker has **no
observable effect** on the decorator path. The pre-existing limitation that
`cache_page` does not natively support async views is unchanged and out of scope.

## F4 — Placement of `_async_check()` in `CacheMiddleware`: CONFIRMED SAFE

In `CacheMiddleware.__init__`, `_async_check()` is placed right after
`self.get_response = get_response` (line 180), before `key_prefix`,
`cache_alias`, `cache_timeout`, etc. are assigned. `_async_check()` reads only
`self.get_response`, so executing it before the remaining attribute assignments
is safe. The consistent rule across all four edits is "`_async_check()`
immediately follows the `self.get_response = …` assignment", matching the
canonical `SessionMiddleware` ordering.

## F5 — Boundary cases: `get_response=None` and single-middleware: CONFIRMED SAFE

- Deprecated `get_response=None` path: `iscoroutinefunction(None) == False`, so
  `_async_check()` does not set `_is_coroutine`. The instance stays sync, matching
  base-class behavior. No deprecation warnings are added or duplicated.
- WSGI mode: `get_response` is the sync `_get_response` wrapper, so
  `_async_check()` does not set the marker. The fix is a no-op under WSGI — no
  behavior change, no regression.
- Single async middleware: still resolves to an `HttpResponse` (the top-level
  `get_response_async` awaits the chain). The fix makes the wrapper genuinely
  async rather than relying on that lucky top-level await — strictly more correct,
  no regression.

## F6 — Approach: `_async_check()` vs `super().__init__()`: V1 APPROACH IS RIGHT

A `super().__init__(get_response)` refactor was considered and rejected:

- It would re-run `_get_response_none_deprecation(get_response)` (already called at
  the top of each subclass `__init__`), double-firing the deprecation warning,
  unless each subclass body is also rewritten to drop its own deprecation call and
  `get_response` assignment — a larger, riskier change.
- For `CacheMiddleware`, `super().__init__()` resolves via MRO to
  `UpdateCacheMiddleware.__init__`, which sets `cache_timeout`/`page_timeout` and
  is **not** the initialization `CacheMiddleware` wants. This would be an outright
  bug.

Adding `_async_check()` is the minimal, local, MRO-safe change and exactly mirrors
the already-correct `SessionMiddleware`.

## F7 — Consistency with codebase conventions: CONFIRMED

The edits reproduce, verbatim, the established `SessionMiddleware` pattern
(`self.get_response = get_response` then `self._async_check()`). They also align
the four middlewares with the base `MiddlewareMixin.__init__` contract that every
non-overriding middleware already satisfies.

## F8 — Marker-consumer audit: CONFIRMED PRECISE

Searched every use of `iscoroutinefunction` / `_is_coroutine` in `django/`. The
instance-level `_is_coroutine` marker set by `_async_check()` is consulted in
exactly one place relevant to middleware instances: `convert_exception_to_response`
(`core/handlers/exception.py:34`). The chain-wrapping `adapt_method_mode`
(`base.py`) calls for the handler pass `method_is_async` explicitly (not `None`),
so they don't re-derive it from the instance; the `process_view` /
`process_template_response` / `process_exception` adaptations operate on **bound
methods** whose async-ness derives from `async def`, not from the instance marker.
Thus the fix has no unintended side effects beyond making the exception wrapper
choose the correct async/sync `inner`.

## F9 — Documentation comment (observation, no action)

Each fixed `__init__` carries a `RemovedInDjango40Warning` comment showing the
future signature `def __init__(self, get_response):`. It shows only the signature,
not the body, so it does not contradict the added `_async_check()` line and needs
no update. Noted for completeness; no change made.

---

## Verdict

The review surfaced **no correctness, regression, edge-case, or convention
problems**. V1 is correct (F1), complete (F2), regression-free (F3, F5),
side-effect-free (F8), safely ordered (F4), and idiomatic (F6, F7). V1 stands
unchanged.
