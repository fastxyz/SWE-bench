# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no unresolved source defect after
formalizing the public intent and proof obligations for async
`View.http_method_not_allowed()`.

## Trace from findings and obligations

- `F1` identified the original bug: async unsupported-method fallback returned a
  raw `HttpResponseNotAllowed`, which the async caller tried to await. `PO2`
  requires the async fallback to return an awaitable, and `PO4` requires that
  awaitable to preserve the 405 response. V1 discharges both by constructing the
  response once and returning `func()` from a nested async function when
  `self.view_is_async` is true.
- `F2` required preserving sync behavior. `PO3` requires a sync unsupported
  method to return the direct response, and V1 keeps that behavior in the
  `else: return response` branch.
- `F3` required preserving the response contract. `PO4` and `PO8` require the
  same `HttpResponseNotAllowed(self._allowed_methods())` response and
  allowed-method list. V1 only moved that construction into a local `response`
  variable before the sync/async branch.
- `F4` checked public compatibility. `PO7` and `PO9` require the public method
  signature, dispatch call shape, and mixed-handler validation to remain
  unchanged. V1 does not change any of those surfaces.
- `F5` records the formal proof limit: the mini semantics cover the local
  fallback return shape, not the whole Django lifecycle. `PO10` requires the
  proof to stay labeled constructed, not machine-checked, and no tests were run
  or edited.

## Alternatives considered during FVK

- I did not refactor a shared helper for `options()` and
  `http_method_not_allowed()`. No finding or proof obligation requires that
  refactor, and `F4`/`PO7` favor a minimal compatibility-preserving change.
- I did not change `View.dispatch()` to wrap all non-awaitable results for async
  views. That would exceed `F1`'s localized cause and could change behavior for
  custom handlers outside `PO2`.
- I did not make `http_method_not_allowed()` an `async def` method because that
  would violate `F2` and `PO3` for sync views.

## Verification status

The FVK artifacts include the five requested markdown files plus the supporting
K and adequacy files under `fvk/`. The K commands are written in `fvk/PROOF.md`
but were not executed, per the benchmark instructions.
