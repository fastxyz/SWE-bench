# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, test,
Python, or Django code was executed.

## Formal files

- `fvk/mini-django-view.k`: a minimal semantics for the relevant dispatch and
  awaitable-result behavior.
- `fvk/django-view-spec.k`: K claims for async unsupported methods, sync
  unsupported methods, allowed-method response preservation, and `options()`
  parity.

Exact commands to machine-check later, not run in this workspace:

```sh
kompile fvk/mini-django-view.k --backend haskell -I fvk
kast --backend haskell -I fvk fvk/django-view-spec.k
kprove fvk/django-view-spec.k -I fvk
```

Expected machine-check result after a valid K setup: `#Top`.

## Claims proved by construction

### C1: Async unsupported method fallback

For an in-domain async `View` subclass where the requested HTTP method has no
handler, `dispatch()` selects `http_method_not_allowed()`. V1 constructs
`HttpResponseNotAllowed(self._allowed_methods())`, then because
`self.view_is_async` is true, returns the result of calling a nested async
function that resolves to that response. Therefore the dispatch result is
awaitable and awaiting it yields the same 405 response.

Discharges: `PO1`, `PO2`, `PO4`, `PO6`, `PO8`.

### C2: Sync unsupported method fallback

For an in-domain sync `View` subclass where the requested HTTP method has no
handler, `dispatch()` selects `http_method_not_allowed()`. V1 constructs the
same `HttpResponseNotAllowed(self._allowed_methods())`, then because
`self.view_is_async` is false, returns the response directly.

Discharges: `PO3`, `PO4`, `PO6`, `PO8`.

### C3: Supported method frame condition

V1 does not edit `View.dispatch()` or any concrete HTTP method handler. If
`dispatch()` finds a handler for the requested method, it calls and returns that
handler exactly as before.

Discharges: `PO5`.

### C4: Compatibility frame condition

V1 does not edit the `http_method_not_allowed(self, request, *args, **kwargs)`
signature and does not alter the virtual dispatch call shape
`handler(request, *args, **kwargs)`. Subclass overrides remain source-compatible.

Discharges: `PO7`, `PO9`.

## Symbolic proof sketch

Let `Allowed = self._allowed_methods()`.

### Async case

1. Precondition: `view_is_async(self) = True`; request method is unsupported by
   the class.
2. `dispatch()` chooses `handler = self.http_method_not_allowed`.
3. Enter `http_method_not_allowed(request, *args, **kwargs)`.
4. The logging call has no effect on the returned value.
5. Execute `response = HttpResponseNotAllowed(Allowed)`.
6. By `DA2`, `response.status_code = 405` and `response["Allow"]` is the joined
   value of `Allowed`.
7. Evaluate `if self.view_is_async`; the true branch is selected.
8. The nested async function captures `response` and returns it.
9. `return func()` returns a coroutine object.
10. Awaiting that coroutine yields the captured `response`.

The postcondition is an awaitable fallback result whose awaited value is the
same 405 response. This removes the pre-V1 `TypeError` mechanism, which arose
because step 9 returned the raw response instead of a coroutine.

### Sync case

1. Precondition: `view_is_async(self) = False`; request method is unsupported by
   the class.
2. `dispatch()` chooses `handler = self.http_method_not_allowed`.
3. Enter `http_method_not_allowed(request, *args, **kwargs)`.
4. Execute `response = HttpResponseNotAllowed(Allowed)`.
5. By `DA2`, `response.status_code = 405` and `response["Allow"]` is the joined
   value of `Allowed`.
6. Evaluate `if self.view_is_async`; the false branch is selected.
7. `return response` returns the direct response.

The postcondition is the same sync result shape as before V1.

## Adequacy audit

The formal claims are adequate for the public intent because they model the
reported mechanism, not merely the changed line:

- The symptom was an async caller awaiting a raw `HttpResponseNotAllowed`.
- The modeled pre-V1 failure is exactly `await(raw405) -> TypeError`.
- The modeled V1 behavior is `await(awaitable(raw405)) -> raw405`.
- The allowed-method response construction is represented separately so the
  proof does not "fix" the awaitability issue by changing the 405 response.

The proof is intentionally partial correctness. It says that if execution
reaches and returns from the fallback, the returned value has the required
shape and response payload. It does not prove process-level termination,
middleware behavior, logging internals, or full ASGI/WSGI integration.

## Test redundancy recommendation

No tests were modified. Because this proof is constructed but not
machine-checked, no test removal is recommended now. If the K commands later
machine-check, narrow unit tests that assert only the direct sync fallback or
the async awaitable fallback could be considered subsumed by this proof, but
integration tests for the Django request/response lifecycle should be kept.
