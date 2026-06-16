# Intent Specification

Status: constructed, not machine-checked.

Intent-only obligations from public evidence:

1. Class-based `View` subclasses may define async HTTP method handlers.
2. A class with async handlers is detected as async and run through an async
   calling path.
3. For an async-only view that does not support the requested method,
   unsupported-method handling must result in a 405 response, not a 500
   `TypeError`.
4. `http_method_not_allowed()` must handle sync and async cases like
   `options()`: direct response for sync, awaitable response for async.
5. The `HttpResponseNotAllowed` response must preserve its status and allowed
   methods.
6. The public method signature and subclass override shape must remain
   compatible.

Observed V1 behavior is checked against these obligations but is not used as an
independent source of expected behavior.
