# Baseline notes — django__django-13344

## Issue

Under ASGI, the **first** middleware in `MIDDLEWARE` receives a `coroutine`
(instead of an `HttpResponse`) in its `process_response()`, but only when there
are at least two middlewares in the chain. All middlewares further down receive
a proper `HttpResponse`.

## Root cause

`MiddlewareMixin` supports both sync and async operation. Its async behaviour is
driven by the `_is_coroutine` "magic" attribute, which `asyncio.iscoroutinefunction()`
checks to decide whether a *callable object* (not just a function) should be
treated as a coroutine function.

`MiddlewareMixin.__init__` sets this up via `self._async_check()`
(`django/utils/deprecation.py`):

```python
def _async_check(self):
    if asyncio.iscoroutinefunction(self.get_response):
        # Marks the instance as async-capable so iscoroutinefunction() == True
        self._is_coroutine = asyncio.coroutines._is_coroutine
```

So when an async `get_response` is passed in, the middleware **instance** must
mark itself with `_is_coroutine` so that the code wrapping/calling it can detect
that calling it returns a coroutine.

Several middlewares override `__init__` and assign `self.get_response`
themselves **without** calling `self._async_check()` (or `super().__init__()`):

- `django/middleware/security.py` — `SecurityMiddleware`
- `django/middleware/cache.py` — `UpdateCacheMiddleware`, `FetchFromCacheMiddleware`,
  `CacheMiddleware`

Because `_async_check()` is never run for these instances, `_is_coroutine` is
missing and `asyncio.iscoroutinefunction(instance)` returns `False` even though
the instance was given an async `get_response` and will, when called, dispatch
to the async `__acall__` and return a coroutine.

### Why this produces a coroutine at the *previous* middleware

The chain is built bottom-up in `BaseHandler.load_middleware`. After each
middleware instance is created it is wrapped with `convert_exception_to_response`
(`django/core/handlers/exception.py`), which branches on
`asyncio.iscoroutinefunction(get_response)`:

- async → returns an `async def inner` (a coroutine function),
- sync  → returns a plain `def inner`.

If, say, `SecurityMiddleware` is missing `_is_coroutine`, this branch wrongly
picks the **sync** `inner`. That sync `inner` then becomes the `get_response`
of the *preceding* middleware (e.g. the user's `DummyMiddleware`).

At runtime `MiddlewareMixin.__call__` does:

```python
if asyncio.iscoroutinefunction(self.get_response):
    return self.__acall__(request)
...
response = response or self.get_response(request)   # sync path
...
response = self.process_response(request, response)
```

Since the preceding middleware sees a *sync-looking* `get_response`, it stays on
the sync path, calls it **without awaiting**, and `SecurityMiddleware.__acall__`
returns an un-awaited coroutine. That coroutine is then handed straight to the
preceding middleware's `process_response()` — exactly the reported symptom.

With a single middleware the chain's top-level result is awaited by
`get_response_async`, so the coroutine is resolved before anyone's
`process_response` is reached, which is why the bug only appears with two or
more middlewares (matching the public hint).

## Fix

Add `self._async_check()` immediately after `self.get_response = get_response`
in the four affected `__init__` methods, mirroring the existing, correct pattern
already used by `SessionMiddleware`
(`django/contrib/sessions/middleware.py:17-18`).

### Files changed

- `django/middleware/security.py`
  - `SecurityMiddleware.__init__`: added `self._async_check()` after the
    `self.get_response = get_response` assignment.
- `django/middleware/cache.py`
  - `UpdateCacheMiddleware.__init__`: added `self._async_check()`.
  - `FetchFromCacheMiddleware.__init__`: added `self._async_check()`.
  - `CacheMiddleware.__init__`: added `self._async_check()` right after
    `self.get_response = get_response` (the call only depends on
    `self.get_response`, which is set first, so the rest of the init is
    unaffected).

These are the only middlewares in `django/` that assign `self.get_response`
without running the async check; `SessionMiddleware` already calls
`_async_check()` and `RedirectFallbackMiddleware` already calls
`super().__init__(get_response)`, so both were left untouched.

## Assumptions / alternatives considered

- **Add `_async_check()` vs. call `super().__init__(get_response)`.** Calling
  `super().__init__()` would also work for `SecurityMiddleware`/`Update`/`Fetch`,
  but it re-runs the deprecation check and the `get_response` assignment, and for
  `CacheMiddleware` the MRO would route into `UpdateCacheMiddleware.__init__`
  (running unrelated cache-setup logic). Adding the single `_async_check()` call
  is the minimal, surgical change and is identical to how `SessionMiddleware`
  solves the same problem. Rejected the `super()` refactor as more invasive.

- **Fixing detection in `load_middleware`/`convert_exception_to_response`
  instead.** The handler-chain code already tracks sync/async correctly for its
  own wrapping; the actual defect is that these instances misreport their async
  capability via `iscoroutinefunction()`. The documented mechanism for an
  instance to report this is the `_is_coroutine` marker set by `_async_check()`,
  so fixing it at the instance level is the correct layer. Rejected changing the
  handler code.

- **Setting `_is_coroutine` from the class-level `async_capable` flag.** That
  would be incorrect: whether a middleware behaves asynchronously depends on the
  concrete `get_response` it is handed at runtime (sync vs. async server), not on
  its static capability. `_async_check()` already makes this per-instance
  decision correctly. Rejected.
