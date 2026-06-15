# FVK Findings

Status: constructed, not machine-checked.

## F-001: Resolved SecurityMiddleware async-recognition defect

Classification: code bug fixed by V1.

Input/scenario: ASGI middleware chain with an outer `MiddlewareMixin`
middleware before `django.middleware.security.SecurityMiddleware`, and an async
downstream handler.

Observed before V1: the outer middleware's `process_response()` could receive a
coroutine instead of an `HttpResponse`, matching the public issue.

Expected: the security middleware instance is recognized as async, the exception
wrapper awaits it, and the outer `process_response()` receives an `HttpResponse`.

Evidence: E1, E2, E3, E5, E6, E7. Proof obligations: PO-001, PO-002, PO-005.

V1 status: discharged by `SecurityMiddleware.__init__()` calling
`super().__init__(get_response)` at `repo/django/middleware/security.py:11`.

## F-002: Resolved cache middleware family defect

Classification: code bug fixed by V1.

Input/scenario: ASGI middleware chain containing
`UpdateCacheMiddleware`, `FetchFromCacheMiddleware`, or `CacheMiddleware` around
an async downstream handler.

Observed before V1: the same missing `MiddlewareMixin._async_check()` pattern
could make these cache middleware instances fail async recognition.

Expected: each cache middleware constructor executes the mixin async
initialization effect, so async downstream handlers are awaited in the chain.

Evidence: E4, E5, E6, E7. Proof obligations: PO-001, PO-003, PO-004, PO-005.

V1 status: discharged by `super().__init__(get_response)` in
`UpdateCacheMiddleware` and `FetchFromCacheMiddleware`, and by
`MiddlewareMixin.__init__(self, get_response)` in `CacheMiddleware`.

## F-003: CacheMiddleware parent-constructor call would be a compatibility risk

Classification: compatibility finding resolved by V1 design.

Input/scenario: `cache_page()` creates `CacheMiddleware` with explicit
`page_timeout`, `cache_alias`, or `key_prefix`.

Risky alternative: using plain `super().__init__(get_response)` in
`CacheMiddleware` would enter `UpdateCacheMiddleware.__init__()` and
`FetchFromCacheMiddleware.__init__()` through the multiple-inheritance MRO
before `CacheMiddleware` applies its own keyword options.

Expected: combined cache middleware should execute only the mixin async
initialization effect, then preserve its existing option handling.

Evidence: E8. Proof obligations: PO-004, PO-007.

V1 status: discharged by direct `MiddlewareMixin.__init__()` in
`CacheMiddleware`, followed by the unchanged option-handling body.

## F-004: Other in-tree custom middleware constructors do not expand the fix scope

Classification: completeness check, no code change required.

Input/scenario: other `MiddlewareMixin` subclasses with custom constructors.

Observed: `SessionMiddleware` already performs `_async_check()` after assigning
`get_response`; `RedirectFallbackMiddleware` already calls
`super().__init__(get_response)`.

Expected: no additional constructor in the searched in-tree middleware family
needs this specific fix.

Evidence: public source audit. Proof obligations: PO-008.

V1 status: no change required.

## F-005: Proof is constructed only; no tests should be removed

Classification: proof/tooling limitation, not a source-code defect.

Input/scenario: FVK artifacts include K claims and proof reasoning, but this
benchmark forbids running `kompile`, `kast`, `kprove`, Python, or tests.

Observed: no machine-check result exists.

Expected: report the proof as constructed, not machine-checked, and make no test
removal recommendation.

Evidence: FVK docs and benchmark instructions. Proof obligations: all.

V1 status: no source change required.
