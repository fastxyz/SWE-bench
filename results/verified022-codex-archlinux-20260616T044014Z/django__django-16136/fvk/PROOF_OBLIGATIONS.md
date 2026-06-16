# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1: Intent adequacy for unsupported async methods

- Claim: the formal spec must represent the public issue's actual failure mode:
  async class-based view, unsupported request method, fallback through
  `http_method_not_allowed()`.
- Evidence: `E1`, `E2`, `E3`.
- Discharge status: discharged by `ASYNC-NOT-ALLOWED-AWAITABLE` and
  `ASYNC-NOT-ALLOWED-AWAIT` in `fvk/django-view-spec.k`.
- Related findings: `F1`.

## PO2: Async fallback returns an awaitable

- Claim: if `self.view_is_async` is true and `dispatch()` selects
  `http_method_not_allowed()`, the returned value is awaitable.
- Evidence: `E1`, `E2`, `E4`.
- Discharge status: discharged by the V1 branch:
  `if self.view_is_async: async def func(): return response; return func()`.
- Related findings: `F1`.

## PO3: Sync fallback returns a direct response

- Claim: if `self.view_is_async` is false and `dispatch()` selects
  `http_method_not_allowed()`, the returned value is a direct
  `HttpResponseNotAllowed`, not a coroutine.
- Evidence: `E2`, `E5`.
- Discharge status: discharged by the V1 `else: return response` branch.
- Related findings: `F2`.

## PO4: The fallback response remains a 405 with allowed methods

- Claim: both sync and async fallback paths produce the same
  `HttpResponseNotAllowed(self._allowed_methods())` response payload.
- Evidence: `E5`, `DA2`.
- Discharge status: discharged because V1 constructs `response` once before the
  sync/async branch and returns or awaits that same response.
- Related findings: `F1`, `F2`, `F3`.

## PO5: Supported method dispatch is unchanged

- Claim: when a requested method has a corresponding handler, V1 does not alter
  selection or return behavior.
- Evidence: `View.dispatch()` source; V1 edits only
  `http_method_not_allowed()`.
- Discharge status: discharged as a frame condition. No code in supported
  handler selection was edited.
- Related findings: none.

## PO6: `http_method_not_allowed()` follows the `options()` adaptation pattern

- Claim: `http_method_not_allowed()` must handle sync and async cases in the
  same way as `options()`: response construction followed by direct return for
  sync views and coroutine wrapping for async views.
- Evidence: public hint `E2`; local `options()` implementation and async tests
  `E6`.
- Discharge status: discharged. V1 mirrors the `options()` branch structure.
- Related findings: `F1`, `F2`.

## PO7: Public method signature and virtual dispatch compatibility

- Claim: the fix must not change the public signature or dispatch call protocol
  for `http_method_not_allowed()`.
- Evidence: `E7`.
- Discharge status: discharged. The method signature and
  `handler(request, *args, **kwargs)` call shape are unchanged.
- Related findings: `F4`.

## PO8: `_allowed_methods()` is called exactly for the response

- Claim: the allowed method list used in the 405 response remains supplied by
  `_allowed_methods()` on the same view instance.
- Evidence: `E5`; source in `View._allowed_methods()`.
- Discharge status: discharged. V1 changed `return
  HttpResponseNotAllowed(self._allowed_methods())` to `response =
  HttpResponseNotAllowed(self._allowed_methods())`, then returns/wraps
  `response`.
- Related findings: `F3`.

## PO9: Mixed sync/async handler rejection remains out of domain

- Claim: the proof need not define successful fallback behavior for classes with
  mixed sync and async handlers because `as_view()` rejects them through
  `view_is_async`.
- Evidence: docs `E4`; source in `View.view_is_async`.
- Discharge status: discharged as domain assumption `DA1`; V1 does not change
  this validation.
- Related findings: `F4`.

## PO10: Honesty gate and proof limits

- Claim: the FVK result must be labeled constructed, not machine-checked, and
  must not claim full Django lifecycle verification or delete tests.
- Evidence: FVK `verify.md` honesty gate.
- Discharge status: discharged by labels and by retaining all tests unchanged.
- Related findings: `F5`.
