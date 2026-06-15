# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were executed.

## Model

The abstract K model in `fvk/mini-python-middleware.k` keeps exactly the issue's
observable property axis:

- whether the constructor argument `get_response` is async;
- whether the initialized middleware instance is recognized as async;
- whether constructor-specific attributes/options remain initialized.

This abstraction distinguishes the failing pre-fix shape from the fixed shape:
with async `get_response`, a constructor that only assigns `self.get_response`
but skips `_async_check()` reaches `recognizedAsync = false`; a constructor that
executes `MiddlewareMixin.__init__()` reaches `recognizedAsync = true`.

## Claim Proofs

`securityInit(true)` rewrites to `mixinInit(true) ~> setSecurity`. The
`mixinInit` rule sets `getResponseIsAsync = true` and
`recognizedAsync = true`. `setSecurity` sets `securityAttrsSet = true` and
frames the async-recognition fields. Therefore the post-state is
`obj(true, true, true, false, false)`, proving PO-002 for the async case.

`securityInit(false)` follows the same two-step rewrite with `false`, proving
the synchronous frame condition PO-006 for the security constructor.

`updateCacheInit(true)` and `fetchCacheInit(true)` each rewrite to
`mixinInit(true) ~> setCache`. The mixin step sets async recognition true; the
cache step sets `cacheAttrsSet = true` and frames async recognition. Therefore
both split cache constructor claims discharge PO-003.

`combinedCacheInit(true)` rewrites to
`mixinInit(true) ~> setCombinedCacheOptions`. The mixin step sets async
recognition true; the combined-cache step sets `cacheAttrsSet = true` and
`combinedCacheOptionsPreserved = true`. This discharges PO-004 and PO-007.

No loops or recursion are present in this proof target, so there are no loop
circularities or termination measures.

## Handler-Chain Proof

From PO-001 through PO-004, each affected middleware instance wrapping an async
handler is recognized as async after construction.

`BaseHandler.load_middleware()` constructs the middleware instance, then passes
that instance to `convert_exception_to_response()`. `convert_exception_to_response()`
selects its async wrapper exactly when `asyncio.iscoroutinefunction(get_response)`
is true. In that branch it awaits `get_response(request)` before returning the
response. Therefore, once the constructor claims hold, the next outer middleware
receives the awaited `HttpResponse` rather than an unawaited coroutine. This
discharges PO-005 and the issue symptom.

## Compatibility Proof

The source diff does not change constructor signatures or
`process_request()`/`process_response()` bodies. For the split cache classes and
`SecurityMiddleware`, `super().__init__(get_response)` performs the same warning
and `get_response` assignment as the replaced manual code, plus `_async_check()`.

For `CacheMiddleware`, direct `MiddlewareMixin.__init__(self, get_response)`
performs the same mixin effect without entering `UpdateCacheMiddleware.__init__()`
or `FetchFromCacheMiddleware.__init__()` through the MRO. The existing keyword
option body then runs unchanged, preserving `cache_page()` behavior for
`page_timeout`, `cache_alias`, and `key_prefix`.

## Commands To Machine-Check Later

These commands are recorded only; they were not executed.

```sh
kompile fvk/mini-python-middleware.k --backend haskell
kast --backend haskell fvk/middleware-async-spec.k
kprove fvk/middleware-async-spec.k
```

Expected machine-check result if the abstract semantics and claims parse as
written: `#Top` for all claims.

## Test Recommendation

No test files were changed. Because the proof is constructed but not
machine-checked, no test removal is recommended.

Useful tests to keep or add outside this benchmark would cover ASGI middleware
chains with an outer dummy `MiddlewareMixin` around each affected middleware
class, plus a `cache_page()` case with explicit cache options.

## Residual Risk

The proof is over a small abstract K semantics, not full Python semantics. The
trusted base is the adequacy of that abstraction for the issue property, the
source-level branch reasoning for Django's handler wrapper, and a future
successful K machine check. The FVK findings do not depend on hidden tests or
runtime execution.
