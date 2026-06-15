# FVK Specification

Status: constructed, not machine-checked.

## Scope

The audited production change is the V1 middleware constructor fix in:

- `repo/django/middleware/security.py`
- `repo/django/middleware/cache.py`

The FVK unit is the constructor-to-handler-classification path for
`SecurityMiddleware`, `UpdateCacheMiddleware`, `FetchFromCacheMiddleware`, and
`CacheMiddleware` when Django builds an ASGI middleware chain.

## Intent Spec

I1. In ASGI mode, a middleware's `process_response(request, response)` must
receive an `HttpResponse`, not an unawaited coroutine, when the downstream
handler is async.

I2. A `MiddlewareMixin` subclass that declares async capability and wraps an
async `get_response` must be recognized by `asyncio.iscoroutinefunction()` as
async after construction.

I3. `SecurityMiddleware` is in scope because the public issue and hint identify
its constructor as missing the `MiddlewareMixin` initialization path.

I4. The three cache middleware classes are in scope because the public hints
identify them as the same constructor family defect.

I5. The fix must preserve existing constructor signatures and settings/cache
attribute initialization.

I6. `CacheMiddleware` must preserve its decorator keyword behavior for
`page_timeout`, `cache_alias`, and `key_prefix`.

## Public Evidence Ledger

E1, prompt: "Coroutine passed to the first middleware's process_response()
instead of HttpResponse." Obligation: downstream async middleware must be
awaited before outer `process_response()` receives a response. Status: encoded
by PO-005.

E2, prompt reproduction: first middleware before
`django.middleware.security.SecurityMiddleware` sees `<class 'coroutine'>`;
moving it down sees `HttpResponse`. Obligation: the defect is in the middleware
chain segment containing `SecurityMiddleware`, not in the dummy middleware.
Status: encoded by PO-002 and PO-005.

E3, public hint: `SecurityMiddleware.__init__()` does not call
`super().__init__()`, so `MiddlewareMixin._async_check()` is not called and the
`_is_coroutine` marker is missing. Obligation: `SecurityMiddleware.__init__()`
must execute `MiddlewareMixin.__init__()` or an equivalent complete effect.
Status: encoded by PO-001 and PO-002.

E4, public hint: the cache-related middlewares have the same issue and should be
fixed together. Obligation: include `UpdateCacheMiddleware`,
`FetchFromCacheMiddleware`, and `CacheMiddleware`. Status: encoded by PO-003
and PO-004.

E5, implementation evidence:
`MiddlewareMixin.__init__()` assigns `self.get_response` and calls
`self._async_check()` at `repo/django/utils/deprecation.py:94`. `_async_check()`
sets `_is_coroutine` when `get_response` is a coroutine function at
`repo/django/utils/deprecation.py:100`. Obligation: constructor proof must carry
this postcondition. Status: encoded by PO-001.

E6, implementation evidence:
`BaseHandler.load_middleware()` constructs the middleware instance and then
wraps it with `convert_exception_to_response(mw_instance)` at
`repo/django/core/handlers/base.py:58` and `repo/django/core/handlers/base.py:88`.
Obligation: constructor async recognition feeds the next handler wrapper.
Status: encoded by PO-005.

E7, implementation evidence:
`convert_exception_to_response()` awaits `get_response` only in the branch where
`asyncio.iscoroutinefunction(get_response)` is true at
`repo/django/core/handlers/exception.py:34`. Obligation: the affected
middleware instance must satisfy that predicate in ASGI mode. Status: encoded
by PO-005.

E8, implementation evidence:
`cache_page()` passes `page_timeout`, `cache_alias`, and `key_prefix` into
`CacheMiddleware` through `decorator_from_middleware_with_args()`. Obligation:
combined cache initialization must not run parent cache initializers in a way
that overrides or preempts explicit decorator options. Status: encoded by
PO-004 and PO-007.

## Formal Spec English

FE1. `mixinInit(B)` terminates with the stored `get_response` async flag equal
to `B` and the middleware instance's async-recognition flag equal to `B`.

FE2. `securityInit(true)` terminates with async recognition true and security
attributes initialized. `securityInit(false)` terminates with async recognition
false and security attributes initialized.

FE3. `updateCacheInit(true)` and `fetchCacheInit(true)` terminate with async
recognition true and cache attributes initialized.

FE4. `combinedCacheInit(true)` terminates with async recognition true, cache
attributes initialized, and combined-cache keyword option handling preserved.

FE5. If an affected middleware instance is recognized as async, the handler
wrapper chosen by `convert_exception_to_response()` is the async wrapper and
awaits the downstream response before returning to the outer middleware.

## Spec Audit

FE1 passes: it restates the documented `MiddlewareMixin.__init__()` and
`_async_check()` effect used by the public hint.

FE2 passes: it covers the issue's named `SecurityMiddleware` ASGI defect and
preserves the sync case as a frame condition.

FE3 passes: it covers the public hint's cache-family expansion for the split
cache middleware classes.

FE4 passes: it covers the same cache-family expansion for the combined
middleware and adds the cache decorator compatibility obligation from public
source callsites.

FE5 passes: it connects the constructor postcondition to the reported symptom
through the actual handler wrapper branch.

No required behavior is marked failed or ambiguous.

## Public Compatibility Audit

Changed public symbols:

- `SecurityMiddleware.__init__(self, get_response=None)`
- `UpdateCacheMiddleware.__init__(self, get_response=None)`
- `FetchFromCacheMiddleware.__init__(self, get_response=None)`
- `CacheMiddleware.__init__(self, get_response=None, cache_timeout=None,
  page_timeout=None, **kwargs)`

Signature compatibility: unchanged for all four constructors.

Return/instance shape compatibility: unchanged; all constructors still return
initialized middleware instances and do not change `process_request()` or
`process_response()` behavior.

Subclass/override compatibility: no public in-tree subclass of these four
middleware classes was found under `repo/django`. Other custom middleware
constructors were checked: `SessionMiddleware` already calls `_async_check()`,
and `RedirectFallbackMiddleware` already calls `super().__init__()`.

Cache decorator compatibility: preserved. `CacheMiddleware` calls
`MiddlewareMixin.__init__()` directly, then retains its existing keyword option
logic, so `cache_page()` callers still control `page_timeout`, `cache_alias`,
and `key_prefix`.

## K Artifacts

The abstract mini-semantics is in `fvk/mini-python-middleware.k`; the claims
are in `fvk/middleware-async-spec.k`. They model the property axis that matters
for this issue: whether an initialized middleware instance is recognized as
async and whether constructor-specific attributes/options remain initialized.
