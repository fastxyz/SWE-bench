# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Decision for V2

V1 stands unchanged. The FVK audit found that the V1 source edit discharges the
publicly derived obligations:

- `F1` is resolved by `PO2`: async fallback now returns an awaitable.
- `F2` is confirmed by `PO3`: sync fallback still returns a direct response.
- `F3` is confirmed by `PO4` and `PO8`: the same
  `HttpResponseNotAllowed(self._allowed_methods())` response is used.
- `F4` is confirmed by `PO7`: signature and virtual dispatch compatibility are
  unchanged.
- `F5` is a proof-scope limit, not a source defect.

## Changes not made

- No source refactor was made. A helper shared by `options()` and
  `http_method_not_allowed()` would reduce a small duplication but is not needed
  to satisfy any finding or proof obligation and would broaden the patch.
- `View.dispatch()` was not changed. Wrapping all non-awaitable returns for
  async views would be broader than the public issue and could mask custom
  handler mistakes. The public hint specifically localizes the obligation to
  `http_method_not_allowed()`.
- `http_method_not_allowed()` was not changed to `async def`. That would break
  the sync fallback contract by returning a coroutine for sync views.
- Tests were not edited or run, per the benchmark instructions.

## Suggested future public tests

These are recommendations only; no test files were modified.

- Add a unit test matching the issue: a `View` subclass with only
  `async def post()` should return/await to a 405 response for `GET`.
- Add a direct method-shape test analogous to the existing async `options()`
  test: `http_method_not_allowed()` should return a coroutine for async view
  classes and a direct response for sync view classes.
- Keep full request/response lifecycle tests because the FVK proof is local and
  constructed, not machine-checked.

## Machine-check follow-up

The emitted K commands in `fvk/PROOF.md` should be run in an environment with K
installed before treating the proof as machine-checked. Until then, all proof
claims remain constructed evidence and all tests should remain in place.
