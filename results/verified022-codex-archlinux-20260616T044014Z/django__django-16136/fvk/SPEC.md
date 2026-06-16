# FVK Specification: async `View.http_method_not_allowed()`

Status: constructed, not machine-checked.

## Scope

This audit covers the Django class-based `View` dispatch path that selects
`http_method_not_allowed()` when a request method is unsupported. The audited
source unit is `repo/django/views/generic/base.py`, specifically:

- `View.view_is_async`
- `View.as_view`
- `View.dispatch`
- `View.http_method_not_allowed`
- `View.options`, as the local comparison pattern named in the public hint
- `View._allowed_methods`, as the source of the `Allow` header

The formal model abstracts Django/Python internals down to the observable needed
for this issue: whether the fallback result is directly an HTTP response or an
awaitable resolving to that response, plus the 405 status and allowed-methods
header.

## Intent-only contract

1. A `View` subclass may define async HTTP method handlers.
2. When all user-defined handlers are async, `as_view()` marks the returned
   callable as coroutine-compatible and Django runs it through an async calling
   path.
3. Unsupported HTTP methods on such async views must produce a normal 405
   `HttpResponseNotAllowed` result, not a `TypeError` from awaiting a plain
   response.
4. `http_method_not_allowed()` must preserve the existing sync behavior: sync
   views receive a direct `HttpResponseNotAllowed`.
5. `http_method_not_allowed()` must preserve the existing response content
   contract: status 405 and an `Allow` header built from `_allowed_methods()`.
6. The async adaptation should match `options()`: create the response, then wrap
   it in a coroutine only when `view_is_async` is true.

## Public evidence ledger

### E1: Issue reproduction

- Source: `benchmark/PROBLEM.md`
- Evidence: "object HttpResponseNotAllowed can't be used in 'await' expression"
  when a view defines only `async def post()` and receives `GET`.
- Semantic obligation: unsupported methods on async-only class-based views must
  not return a plain response to an async caller; the final result must be a 405
  response.
- Status: encoded in K claims `ASYNC-NOT-ALLOWED-AWAITABLE` and
  `ASYNC-NOT-ALLOWED-AWAIT`.

### E2: Public hint

- Source: `benchmark/PROBLEM.md`
- Evidence: "`http_method_not_allowed()` needs to be adjusted to handle both
  sync and async cases in the same way as `options()`."
- Semantic obligation: `http_method_not_allowed()` has a sync branch returning
  the response directly and an async branch returning an awaitable resolving to
  that response.
- Status: encoded in K claims `ASYNC-NOT-ALLOWED-AWAITABLE`,
  `SYNC-NOT-ALLOWED-DIRECT`, and `OPTIONS-PARITY`.

### E3: Django docs for async class-based views

- Source: `repo/docs/topics/class-based-views/index.txt`
- Evidence: class-based view handlers may be async, all handlers in a class
  must be sync or async, and Django automatically detects async views and runs
  them in an async context.
- Semantic obligation: for an async view class, framework fallback handlers
  reached through `dispatch()` must return an awaitable-compatible result.
- Status: encoded as a precondition and postcondition of
  `ASYNC-NOT-ALLOWED-AWAITABLE`.

### E4: Django docs for `as_view()`

- Source: `repo/docs/ref/class-based-views/base.txt`
- Evidence: if a `View` subclass defines async handlers, `as_view()` marks the
  returned callable as a coroutine function; mixed sync and async handlers raise
  `ImproperlyConfigured`.
- Semantic obligation: the in-domain classes for this proof are all-sync,
  all-async, or no-handler views. Mixed-handler classes are out of domain for
  successful dispatch and are handled by existing validation.
- Status: encoded as domain assumption `DA1`; mixed-handler behavior is a frame
  condition, not changed by V1.

### E5: Django docs for `http_method_not_allowed()`

- Source: `repo/docs/ref/class-based-views/base.txt`
- Evidence: unsupported methods call `http_method_not_allowed()`, whose default
  implementation returns `HttpResponseNotAllowed` with allowed methods.
- Semantic obligation: V1 must preserve status 405 and the allowed-methods
  response for both sync and async views.
- Status: encoded in K claims `ASYNC-NOT-ALLOWED-AWAIT`,
  `SYNC-NOT-ALLOWED-DIRECT`, and `ALLOW-HEADER-PRESERVED`.

### E6: Existing local async `options()` behavior

- Source: `repo/django/views/generic/base.py`; supported by
  `repo/tests/async/tests.py`
- Evidence: `options()` creates a response and, if `self.view_is_async`, returns
  a small coroutine resolving to it; tests assert async views receive a
  coroutine from `options()`.
- Semantic obligation: use the same adaptation shape for
  `http_method_not_allowed()`.
- Status: encoded in K claim `OPTIONS-PARITY`.

### E7: Public compatibility surface

- Source: `repo/django/views/generic/base.py` and repository search for
  `def http_method_not_allowed`.
- Evidence: only the base method defines `http_method_not_allowed`; the public
  method signature is `http_method_not_allowed(self, request, *args, **kwargs)`.
- Semantic obligation: V1 must not change signature, dispatch call shape, or the
  override protocol.
- Status: encoded in proof obligation `PO7` and compatibility audit.

## Domain and assumptions

- `DA1`: The view class is in the successful `as_view()` domain: all defined
  HTTP handlers are sync, all are async, or no handlers are defined. Mixed
  sync/async classes remain rejected by existing `view_is_async` validation.
- `DA2`: `HttpResponseNotAllowed(methods)` constructs an HTTP response with
  status 405 and an `Allow` header equal to the joined allowed methods, as
  modeled from `repo/django/http/response.py`.
- `DA3`: A coroutine returned by the small nested async function resolves to the
  captured response when awaited. This is standard Python async semantics and is
  mirrored by the existing `options()` implementation.
- `DA4`: Logging in `http_method_not_allowed()` is not part of the returned value
  except that it must still occur on entry to the fallback. V1 preserves the
  logging call before response wrapping.

## Required postconditions

- `PC1`: For an async view whose requested method has no handler, `dispatch()`
  returns an awaitable; awaiting it yields `HttpResponseNotAllowed` with status
  405 and the `Allow` header from `_allowed_methods()`.
- `PC2`: For a sync view whose requested method has no handler, `dispatch()`
  returns `HttpResponseNotAllowed` directly with status 405 and the same
  `Allow` header.
- `PC3`: The sync/async branch split in `http_method_not_allowed()` is the same
  adaptation strategy as `options()`.
- `PC4`: Existing supported-method dispatch is unchanged.
- `PC5`: Existing public method signatures and subclass override expectations
  are unchanged.

## Adequacy summary

The K claims in `fvk/django-view-spec.k` paraphrase to exactly the postconditions
above. The formal model does not attempt to prove full Django request handling,
middleware adaptation, logging internals, or Python object identity. Those are
outside this issue's required observable and are recorded as proof limits rather
than implementation bugs.
