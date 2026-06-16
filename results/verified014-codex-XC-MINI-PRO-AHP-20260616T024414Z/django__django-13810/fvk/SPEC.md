# FVK Specification: django__django-13810

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Target

The audited unit is `BaseHandler.load_middleware()` in
`repo/django/core/handlers/base.py`, specifically the middleware-loading loop
that computes `(handler, handler_is_async)` and the middleware side lists.

The V1 candidate patch changes the factory call from mutating `handler` before
the call to using a local `adapted_handler`:

```python
adapted_handler = self.adapt_method_mode(...)
mw_instance = middleware(adapted_handler)
```

## Intent-only requirements

I-01. A middleware that raises `MiddlewareNotUsed` is not part of the server
configuration. It must not alter the persistent middleware chain.

I-02. Django adapts sync and async request handling to fit each middleware's
declared `sync_capable` and `async_capable` flags.

I-03. In ASGI mode the completed top-level middleware chain must be awaitable by
`get_response_async()`. A synchronous `HttpResponse` must not be returned on a
path where Django later performs `await self._middleware_chain(request)`.

I-04. `_middleware_chain` is only published when middleware initialization
finishes. Initialization errors may abort loading, but must not publish a
partially constructed chain as complete.

## Public evidence ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-01 | issue | "MiddlewareNotUsed leaves undesired side effects when loading middleware in ASGI context" | A skipped middleware must not leave state used by later middleware. | Encoded by PO-03. |
| E-02 | issue | "it does leave handler variable overwritten with output of self.adapt_method_mode()" | The suspicious state is the persistent `handler`, not merely logging or local wrapper allocation. | Encoded by PO-03 and F-001. |
| E-03 | issue | "the middleware chain [is] 'poisoned' from this point onwards" | The loop invariant must cover every subsequent iteration, not just the skipped middleware itself. | Encoded by PO-02. |
| E-04 | issue | "resulting in last middleware in response cycle to return an HttpResponse as a synchronous middleware would, instead of coroutine that is expected" | In ASGI mode, final chain mode must match `is_async=True`. | Encoded by PO-06. |
| E-05 | docs | `MiddlewareNotUsed` is raised when a middleware is not used in the server configuration. | Not-used middleware contributes no chain element. | Encoded by PO-03. |
| E-06 | docs | "Django will then remove that middleware from the middleware process" | Removal is a frame condition over persistent chain state. | Encoded by PO-03. |
| E-07 | docs | `sync_capable` and `async_capable` indicate whether middleware can handle synchronous or asynchronous requests. | Mode selection must follow capability flags. | Encoded by PO-04 and PO-06. |
| E-08 | source comment | `_middleware_chain` is assigned only when initialization is complete. | Aborted loading must not mark initialization complete. | Encoded by PO-05. |

No hidden tests, evaluator traces, original upstream patches, or internet
sources were used.

## Abstract model

The mini semantics abstracts away request bodies, actual callables, and response
objects. It keeps exactly the property axis manipulated by the bug: the
persistent handler token, the declared mode of that token, and whether a
middleware contributes to the chain.

State variables:

- `H`: persistent handler token.
- `HM`: persistent handler mode, `sync` or `async`.
- `V`, `T`, `E`: view/template/exception middleware lists.
- `P`: published chain flag, initially false and true only at normal exit.
- `M`: next middleware descriptor from `reversed(settings.MIDDLEWARE)`.
- `target(M, HM)`: selected middleware mode:
  - `sync` if `HM == sync` and `M.sync_capable`.
  - otherwise `async` if `M.async_capable`.
  - invalid if neither capability flag is true.
- `adapt(target, H, HM)`: pure wrapper construction whose result may be passed
  to the factory but is not persistent unless explicitly assigned.
- `factory(M, adapted)`: one of `used(instance)`, `not_used`, or `none`.
- `convert(instance)`: exception-to-response wrapper for a used middleware.

The model intentionally treats `adapt()` as pure with respect to persistent
chain state. It may allocate a wrapper and, in Django debug mode, log an
adaptation message, but neither changes `H`, `HM`, `V`, `T`, `E`, or `P`.

## Contract

Preconditions:

- Middleware descriptors are importable.
- Each in-domain descriptor has at least one of `sync_capable` or
  `async_capable`, or the loader raises the existing `RuntimeError` branch.
- A factory returning `None` remains an initialization error and aborts loading
  through the existing `ImproperlyConfigured` branch.

Postconditions for normal completion:

- `P == true` and `_middleware_chain` is assigned exactly once, after the loop
  and final top-level adaptation.
- For every used middleware, the chain contains exactly one corresponding
  `convert(instance)` wrapper, in the order induced by the reversed loading
  loop.
- For every `MiddlewareNotUsed` middleware, the persistent state at the next
  iteration equals the state at the current iteration, except for permitted
  debug logging.
- If `is_async == true`, the final published chain is in async mode.

Frame conditions:

- On `MiddlewareNotUsed`, `H`, `HM`, `V`, `T`, `E`, and `P` are unchanged.
- On successful factory return, only the current middleware's declared process
  hooks may update `V`, `T`, and `E`; `H` becomes `convert(instance)` and `HM`
  becomes `target(M, HM_old)`.
- On invalid capability or `None` factory return, loading aborts before `P`
  becomes true.

## K-style formal core

The following K-style claims are the constructed formal core for this benchmark
artifact. They are written as claims over the abstract mini semantics above and
are intended to be extracted to `mini-middleware-loader.k` and
`middleware-loader-spec.k` before a future machine check.

```k
// SPEC-PROVENANCE:
// - E-01/E-05/E-06: MiddlewareNotUsed means not installed.
// - E-02/E-03: persistent handler must not be overwritten on the skip path.
claim <k> step(MW, H, HM, V, T, E, false)
      => state(H, HM, V, T, E, false) ... </k>
  requires validCaps(MW)
   andBool factoryOutcome(MW, adapt(target(MW, HM), H, HM)) ==K not_used
  [all-path]
```

```k
// SPEC-PROVENANCE:
// - E-07: selected mode follows sync_capable/async_capable.
// - source lines 72-89: process hooks update side lists, then handler updates.
claim <k> step(MW, H, HM, V, T, E, false)
      => state(convert(INST),
               target(MW, HM),
               addViewHooks(MW, INST, V),
               addTemplateHooks(MW, INST, T),
               addExceptionHooks(MW, INST, E),
               false) ... </k>
  requires validCaps(MW)
   andBool factoryOutcome(MW, adapt(target(MW, HM), H, HM)) ==K used(INST)
  [all-path]
```

```k
// SPEC-PROVENANCE:
// - E-03: the invariant covers all later middleware, not only the skipped one.
claim <k> loadLoop(MWS, H, HM, V, T, E, false)
      => loaded(installUsedOnly(MWS, H, HM, V, T, E), false) ... </k>
  requires allImportable(MWS)
  [all-path]
```

```k
// SPEC-PROVENANCE:
// - E-04: ASGI final chain is awaitable.
// - E-08: publish only after initialization is complete.
claim <k> loadMiddleware(IS_ASYNC, MWS)
      => published(finalAdapt(IS_ASYNC, installUsedOnly(MWS, base(IS_ASYNC)))) ... </k>
  requires allImportable(MWS)
  ensures publishedMode ==K requestedMode(IS_ASYNC)
  [all-path]
```

Expected commands for a future machine check, not run here:

```sh
kompile fvk/mini-middleware-loader.k --backend haskell
kast --backend haskell fvk/middleware-loader-spec.k
kprove fvk/middleware-loader-spec.k
```
