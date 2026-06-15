# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: MiddlewareMixin initialization postcondition

Statement: for any constructor argument `get_response`, if
`asyncio.iscoroutinefunction(get_response)` is true, then after
`MiddlewareMixin.__init__()` the instance is recognized as a coroutine function.
If it is false, the constructor must not force async recognition.

Evidence: E3 and E5.

Formal claim coverage: `mixinInit(B)` in `fvk/mini-python-middleware.k`, used by
all claims in `fvk/middleware-async-spec.k`.

Status: discharged in the abstract model.

## PO-002: SecurityMiddleware constructor obligation

Statement: `SecurityMiddleware.__init__()` must execute PO-001 and then preserve
security setting initialization.

Evidence: E1, E2, E3.

Source discharge: `repo/django/middleware/security.py:11` calls
`super().__init__(get_response)` before setting security attributes.

Formal claim coverage: `securityInit(true)` and `securityInit(false)`.

Status: discharged.

## PO-003: Split cache middleware constructor obligation

Statement: `UpdateCacheMiddleware.__init__()` and
`FetchFromCacheMiddleware.__init__()` must execute PO-001 and then preserve
their cache setting initialization.

Evidence: E4 and E5.

Source discharge: `repo/django/middleware/cache.py:66` and
`repo/django/middleware/cache.py:129` call `super().__init__(get_response)`
before setting cache attributes.

Formal claim coverage: `updateCacheInit(true)` and `fetchCacheInit(true)`.

Status: discharged.

## PO-004: Combined CacheMiddleware constructor obligation

Statement: `CacheMiddleware.__init__()` must execute PO-001 while preserving the
combined constructor's explicit keyword option semantics.

Evidence: E4 and E8.

Source discharge: `repo/django/middleware/cache.py:173` calls
`MiddlewareMixin.__init__(self, get_response)`, then the existing option logic
continues through `repo/django/middleware/cache.py:180`.

Formal claim coverage: `combinedCacheInit(true)`.

Status: discharged.

## PO-005: Handler-chain symptom obligation

Statement: in ASGI mode, once an affected middleware instance satisfies async
recognition, `convert_exception_to_response(mw_instance)` must choose the async
wrapper, await the middleware instance, and return an `HttpResponse` rather than
an unawaited coroutine to the next outer middleware.

Evidence: E1, E2, E6, E7.

Source discharge: `BaseHandler.load_middleware()` wraps each constructed
middleware instance at `repo/django/core/handlers/base.py:88`; the wrapper's
async branch awaits `get_response` at
`repo/django/core/handlers/exception.py:34`.

Formal claim coverage: modeled as the `recognizedAsync` postcondition in every
async constructor claim; proved in prose by the handler branch implication.

Status: discharged by constructor claims plus source-level branch reasoning.

## PO-006: Synchronous path frame condition

Statement: constructors must not make a synchronous `get_response` look async.

Evidence: I5 and E5.

Source discharge: `MiddlewareMixin._async_check()` sets `_is_coroutine` only
when `get_response` is a coroutine function.

Formal claim coverage: `securityInit(false)`; the same mixin rule generalizes
to the cache constructors.

Status: discharged.

## PO-007: Public compatibility obligation

Statement: constructor signatures, middleware return shape, and cache decorator
keyword behavior must remain compatible.

Evidence: I5, I6, E8.

Source discharge: signatures are unchanged; `CacheMiddleware` keeps its
existing keyword handling after direct mixin initialization.

Formal claim coverage: `combinedCacheInit(true)` records
`combinedCacheOptionsPreserved = true`.

Status: discharged.

## PO-008: Completeness of the audited constructor family

Statement: no other in-tree custom `MiddlewareMixin` constructor in the searched
middleware set should share the missing async-check defect.

Evidence: E4 plus source audit of other constructors.

Source discharge: `SessionMiddleware` already calls `_async_check()` and
`RedirectFallbackMiddleware` already calls `super().__init__()`.

Formal claim coverage: not encoded as a K claim; this is a public compatibility
and scope audit obligation.

Status: discharged by source inspection.
