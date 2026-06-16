# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbol

`django.views.generic.base.View.http_method_not_allowed`

- Public signature before V1: `http_method_not_allowed(self, request, *args,
  **kwargs)`.
- Public signature after V1: unchanged.
- Return shape before V1: direct `HttpResponseNotAllowed` for all views.
- Return shape after V1: direct response for sync views; awaitable resolving to
  that response for async views.
- Compatibility status: pass. The async return-shape change is the required bug
  fix because async `as_view()` callers already expect awaitable-compatible
  results.

## Callers

- `View.dispatch()` still calls the selected handler as
  `handler(request, *args, **kwargs)`.
- No new keyword arguments or changed positional arguments were introduced.
- Compatibility status: pass.

## Subclass overrides

- Repository search found no in-repo subclass override of
  `http_method_not_allowed()`.
- External overrides remain source-compatible because signature and call shape
  are unchanged.
- If an external async view overrides `http_method_not_allowed()` and returns a
  plain response, it may still reproduce the same class of bug, but that is not
  caused by V1 and cannot be fixed without changing the public override
  contract.
- Compatibility status: pass with documented residual risk for custom overrides.

## Storage, response, and protocol shape

- The response object is still created by
  `HttpResponseNotAllowed(self._allowed_methods())`.
- No response headers, status code, request mutation, or stored attributes were
  changed.
- Compatibility status: pass.
