# Baseline Notes

## Root cause

`MiddlewareMixin.__init__()` stores `get_response` and calls `_async_check()`.
When `get_response` is async, `_async_check()` sets the `_is_coroutine`
marker that lets `asyncio.iscoroutinefunction()` recognize the middleware
instance as async-capable.

`SecurityMiddleware`, `UpdateCacheMiddleware`, `FetchFromCacheMiddleware`, and
`CacheMiddleware` overrode `__init__()` and duplicated only the warning and
`get_response` assignment. They did not call the mixin initializer or
`_async_check()`. Under ASGI, `BaseHandler.load_middleware()` could therefore
treat one of these middleware instances as synchronous even though its wrapped
handler was async. That caused the next middleware outward in the chain to call
it synchronously and receive an unawaited coroutine as the response.

## Files changed

`repo/django/middleware/security.py`

Changed `SecurityMiddleware.__init__()` to call `super().__init__(get_response)`
before reading its settings. This keeps the existing settings-derived
attributes while letting `MiddlewareMixin` perform the deprecation handling,
`get_response` assignment, and async marker setup.

`repo/django/middleware/cache.py`

Changed `UpdateCacheMiddleware.__init__()` and
`FetchFromCacheMiddleware.__init__()` to call `super().__init__(get_response)`
before setting their cache attributes. This restores the mixin async marker for
the two split cache middleware classes.

Changed `CacheMiddleware.__init__()` to call `MiddlewareMixin.__init__()`
directly. `CacheMiddleware` has multiple cache middleware parents and its
constructor deliberately applies decorator-provided options such as
`cache_alias`, `key_prefix`, and timeout values itself. Calling the mixin
directly restores the async marker without running the parent cache
constructors first and doing settings/cache lookups that may then be replaced
by the explicit options.

## Assumptions and alternatives considered

I assumed the intended behavior is that these middleware classes remain
`sync_capable` and `async_capable` through `MiddlewareMixin`, with their
`process_request()` and `process_response()` methods still adapted through
`sync_to_async()` by the existing mixin implementation.

I considered adding `self._async_check()` after the existing manual
`self.get_response = get_response` assignments. That would fix the immediate
coroutine marker problem, but it would continue duplicating part of
`MiddlewareMixin.__init__()` and leave the same class of omission in place.

I considered using `super().__init__(get_response)` in `CacheMiddleware` too,
but rejected it because its method resolution order would enter
`UpdateCacheMiddleware.__init__()` and `FetchFromCacheMiddleware.__init__()`
before `CacheMiddleware` applies its own keyword options. That would add
unnecessary settings/cache initialization and could conflict with explicitly
provided cache options.

No tests or project code were run, per the benchmark instructions.
