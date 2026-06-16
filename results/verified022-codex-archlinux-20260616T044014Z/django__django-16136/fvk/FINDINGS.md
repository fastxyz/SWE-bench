# FVK Findings

Status: constructed, not machine-checked.

## F1: Resolved pre-V1 bug - async fallback returned a non-awaitable response

- Classification: code bug, resolved by V1.
- Input: a `View` subclass with only `async def post()`, request method `GET`.
- Observed before V1: `dispatch()` selected `http_method_not_allowed()`, which
  returned a plain `HttpResponseNotAllowed`; the async caller attempted to await
  that response and raised `TypeError: object HttpResponseNotAllowed can't be
  used in 'await' expression`, causing a 500.
- Expected: the unsupported method path produces a normal 405
  `HttpResponseNotAllowed`.
- Evidence: public issue reproduction `E1`; public hint `E2`; docs evidence
  `E3` and `E4`.
- Related proof obligations: `PO1`, `PO2`, `PO4`, `PO6`.
- V1 assessment: resolved. `http_method_not_allowed()` now returns a coroutine
  resolving to the 405 response when `self.view_is_async` is true.

## F2: Sync fallback behavior is preserved

- Classification: frame condition, confirmed.
- Input: a sync `View` subclass whose requested method is unsupported.
- Observed in V1: `http_method_not_allowed()` constructs
  `HttpResponseNotAllowed` and returns it directly when `self.view_is_async` is
  false.
- Expected: same direct 405 response behavior as before V1.
- Evidence: docs evidence `E5`; public hint requires handling both sync and
  async cases `E2`.
- Related proof obligations: `PO3`, `PO4`, `PO6`.
- V1 assessment: confirmed. No further source change is justified.

## F3: Allowed-method response contract is preserved

- Classification: frame condition, confirmed.
- Input: unsupported method on either sync or async in-domain `View` subclass.
- Observed in V1: the response is still constructed as
  `HttpResponseNotAllowed(self._allowed_methods())`.
- Expected: status 405 with the `Allow` header derived from `_allowed_methods()`.
- Evidence: docs evidence `E5`; implementation of `HttpResponseNotAllowed` in
  `repo/django/http/response.py`.
- Related proof obligations: `PO4`, `PO8`.
- V1 assessment: confirmed. V1 changes only the return shape for async views,
  not the response construction.

## F4: Public compatibility surface is unchanged

- Classification: compatibility check, confirmed.
- Input: public callers and subclasses relying on
  `http_method_not_allowed(self, request, *args, **kwargs)`.
- Observed in V1: method signature, dispatch call shape, method name, and
  subclass override protocol are unchanged.
- Expected: existing overrides and calls continue to work.
- Evidence: repository search found only the base method definition; dispatch
  still calls `handler(request, *args, **kwargs)`.
- Related proof obligations: `PO7`, `PO9`.
- V1 assessment: confirmed. A broader helper/refactor is unnecessary for this
  issue and would add compatibility risk without satisfying a new obligation.

## F5: Formal proof is abstract, not a substitute for integration coverage

- Classification: proof capability and test-retention note.
- Input: full Django request/response lifecycle under WSGI/ASGI, middleware,
  logging, and concrete Python coroutine object behavior.
- Observed in FVK: the mini semantics models only dispatch selection,
  not-allowed response construction, and direct-vs-awaitable return shape.
- Expected: the proof should justify the local source edit but not claim to
  replace integration tests or hidden lifecycle coverage.
- Evidence: FVK honesty gate; scope stated in `SPEC.md`.
- Related proof obligations: `PO10`.
- V1 assessment: no code problem found. Keep tests; any test-redundancy claims
  are conditioned on machine-checking the emitted K commands, which was not run.

## Unresolved findings

None. The FVK audit did not surface a code defect in V1.
