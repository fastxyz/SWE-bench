# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not edit production source further. The V1 local-variable change is the
minimal change that discharges the public-intent obligations:

- `MiddlewareNotUsed` leaves no persistent chain state (PO-03).
- Successful middleware still receives an adapted `get_response` and installs as
  before (PO-04).
- Initialization error behavior and delayed `_middleware_chain` publication are
  unchanged (PO-05).
- ASGI final adaptation now operates on consistent handler/mode state (PO-06).
- No public API or factory calling convention changes (PO-07).

## Recommended future test

When test edits are allowed, add a regression test that constructs an ASGI
middleware load order with:

1. an async downstream handler,
2. a sync-only middleware factory that raises `MiddlewareNotUsed`, and
3. a later async-capable middleware that would fail if `handler` and
   `handler_is_async` diverge.

Expected assertion: after the skipped middleware, the later middleware sees a
`get_response` callable consistent with the loader's async metadata, and the
final chain remains awaitable.

## Future machine-check step

In an environment with K installed, extract the K-style claims from `SPEC.md`
into `fvk/mini-middleware-loader.k` and `fvk/middleware-loader-spec.k`, then run:

```sh
kompile fvk/mini-middleware-loader.k --backend haskell
kast --backend haskell fvk/middleware-loader-spec.k
kprove fvk/middleware-loader-spec.k
```

Until that succeeds with `#Top`, keep ordinary regression tests. Do not remove
tests based on this constructed proof alone.
