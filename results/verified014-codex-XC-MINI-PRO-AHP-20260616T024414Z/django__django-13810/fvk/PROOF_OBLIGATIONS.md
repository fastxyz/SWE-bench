# FVK Proof Obligations

Status legend:

- DISCHARGED: discharged by source inspection and constructed symbolic proof.
- CONSTRUCTED: proof written, not machine-checked.
- NOT RUN: command or test intentionally not executed.

## PO-01: Intent adequacy

Statement:

The formal contract must be derived from public issue text and public Django
source/docs, not from legacy implementation behavior.

Evidence:

- E-01 through E-08 in `SPEC.md`.

Status: DISCHARGED.

Reason:

The core skip-frame obligation comes from the issue report and public docs that
unused middleware is removed from the middleware process. The pre-fix assignment
to `handler` is treated as observed buggy behavior, not as expected behavior.

## PO-02: Middleware-loading loop invariant

Statement:

At the start of every iteration over `reversed(settings.MIDDLEWARE)`,
`handler` and `handler_is_async` describe the chain formed by exactly the
successfully used middleware from the suffix already processed. The view,
template-response, and exception middleware lists likewise contain only hooks
from successfully used middleware.

Status: DISCHARGED.

Reason:

Initialization establishes the invariant with the base response handler and
empty hook lists. PO-03 preserves it on skipped middleware. PO-04 advances it on
successful middleware. PO-05 aborts before publication on error branches.

## PO-03: `MiddlewareNotUsed` frame condition

Statement:

If a middleware factory raises `MiddlewareNotUsed`, the next iteration begins
with the same persistent `handler`, `handler_is_async`, and hook lists as the
current iteration.

Status: DISCHARGED.

Reason:

In V1, `self.adapt_method_mode(...)` writes to local `adapted_handler`, not
`handler`. If the factory raises `MiddlewareNotUsed`, control jumps to the
`except` block and `continue`s before any persistent state assignment. The only
permitted side effect is debug logging.

## PO-04: Successful middleware transition

Statement:

If a middleware factory returns a non-`None` instance, that instance receives a
handler adapted to the selected middleware mode, and then the persistent chain
advances to `convert_exception_to_response(mw_instance)` with
`handler_is_async == middleware_is_async`.

Status: DISCHARGED.

Reason:

V1 still passes `adapted_handler` to the factory. The code after the
`MiddlewareNotUsed` handler is unchanged: process hooks are appended/inserted,
then `handler` and `handler_is_async` are updated exactly once.

## PO-05: Error branches do not publish a completed chain

Statement:

Invalid capability declarations and `None` factory returns must abort
initialization before `_middleware_chain` is assigned as complete.

Status: DISCHARGED.

Reason:

The invalid-capability branch raises before adaptation. The `None` branch raises
`ImproperlyConfigured` before the final `_middleware_chain` assignment. V1 does
not change either branch.

## PO-06: Final ASGI mode obligation

Statement:

After normal completion, the final call to `adapt_method_mode(is_async, handler,
handler_is_async)` must receive a `handler` and `handler_is_async` pair that
accurately describes the successfully installed chain, so ASGI mode publishes an
awaitable chain.

Status: DISCHARGED.

Reason:

PO-02 ensures state consistency across the loop. PO-03 removes the stale-mode
counterexample introduced by skipped middleware. Therefore the final adaptation
uses correct mode metadata.

## PO-07: Public compatibility

Statement:

The fix must not change public function signatures, settings names, middleware
factory calling convention, or documented error behavior.

Status: DISCHARGED.

Reason:

The only source change is a local variable inside `load_middleware()`. The
factory still receives one `get_response` argument. No public API, exception
type, setting, or hook list contract is changed.

## PO-08: Machine-check commands

Statement:

The constructed proof should be machine-checkable in a future K environment.

Status: CONSTRUCTED / NOT RUN.

Commands recorded for future use:

```sh
kompile fvk/mini-middleware-loader.k --backend haskell
kast --backend haskell fvk/middleware-loader-spec.k
kprove fvk/middleware-loader-spec.k
```

Expected outcome:

`kprove` should reduce the skip-frame, success-transition, loop-invariant, and
final-mode claims to `#Top`. This expectation is not asserted as
machine-checked in this run.
