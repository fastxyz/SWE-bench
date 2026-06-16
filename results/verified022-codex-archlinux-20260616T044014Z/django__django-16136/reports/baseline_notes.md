# Baseline Notes

## Root cause

`View.as_view()` marks the generated callable as coroutine-compatible when all
defined HTTP handlers on the class are async. `View.dispatch()` still calls the
selected handler normally and returns whatever that handler returns.

For an unsupported HTTP method, `dispatch()` falls back to
`http_method_not_allowed()`. That method always returned a plain
`HttpResponseNotAllowed`. On an async-only view, the surrounding async request
handling path expects the marked view callable to return an awaitable, so it
attempts to await the plain response and raises `TypeError: object
HttpResponseNotAllowed can't be used in 'await' expression`.

`View.options()` already handles the equivalent situation by returning the
response directly for sync views and returning a small coroutine for async views.

## Changed files

`repo/django/views/generic/base.py`

- Updated `View.http_method_not_allowed()` to first create the
  `HttpResponseNotAllowed` response.
- If `self.view_is_async` is true, the method now returns a coroutine that
  resolves to that response, matching the pattern already used by
  `View.options()`.
- If the view is sync, the method still returns the response directly, preserving
  existing sync behavior.

## Assumptions and alternatives considered

- I assumed the intended contract is that every dispatch result from an async
  `View` must be awaitable, including framework-provided fallback handlers such
  as `http_method_not_allowed()`.
- I considered changing `dispatch()` to wrap all non-awaitable results for async
  views, but rejected that as broader than the reported bug and more likely to
  alter behavior for custom handlers.
- I considered making `http_method_not_allowed()` itself an `async def`, but
  rejected that because it would make sync views receive a coroutine from the
  fallback path.
- I did not modify tests or run tests/project code because the task explicitly
  forbids doing so in this benchmark workspace.
