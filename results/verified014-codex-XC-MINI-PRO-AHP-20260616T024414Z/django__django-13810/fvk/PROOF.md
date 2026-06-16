# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Claim

For every in-domain middleware list, `BaseHandler.load_middleware()` builds a
chain from used middleware only. If a middleware raises `MiddlewareNotUsed`, the
persistent chain state used by subsequent middleware is unchanged. On normal
ASGI completion, the published `_middleware_chain` is adapted to async mode.

## State and invariant

Let the loop state be:

```text
S = (H, HM, V, T, E, P)
```

where `H` is the persistent handler token, `HM` is its sync/async mode, `V`,
`T`, and `E` are the view, template-response, and exception middleware lists,
and `P` records whether `_middleware_chain` has been published.

Loop invariant `INV(i, S)`:

After processing the suffix of middleware after index `i`, `H` and `HM`
describe exactly the chain of successfully used middleware in that suffix, and
`V`, `T`, and `E` contain only hooks from those same successfully used
middleware. `P` is false during the loop.

Initialization:

The invariant holds before the first iteration because `H` is
`convert_exception_to_response(get_response)`, `HM == is_async`, all hook lists
are empty, and `P == false`.

## Symbolic step proof

Case 1: invalid capabilities.

If neither `sync_capable` nor `async_capable` is true, the code raises
`RuntimeError` before adapting or publishing. This exits the normal-completion
proof and preserves PO-05.

Case 2: middleware raises `MiddlewareNotUsed`.

V1 executes:

```python
adapted_handler = self.adapt_method_mode(...)
mw_instance = middleware(adapted_handler)
```

The assignment targets local `adapted_handler`, not persistent `handler`.
If `middleware(adapted_handler)` raises `MiddlewareNotUsed`, control enters the
`except` block and then `continue`s. No code between the factory call and
`continue` assigns `handler`, `handler_is_async`, `V`, `T`, or `E`.

Therefore:

```text
(H, HM, V, T, E, false) -> (H, HM, V, T, E, false)
```

on the skip path, discharging PO-03 and preserving `INV` for the next
iteration.

Case 3: middleware returns `None`.

The code raises `ImproperlyConfigured` before hook list updates, before
`handler`/`handler_is_async` updates, and before `_middleware_chain`
publication. This preserves PO-05.

Case 4: middleware returns an instance.

The factory receives `adapted_handler`, so the middleware still observes the
selected target mode. After the factory succeeds, the code updates hook lists
for any process hooks, then assigns:

```python
handler = convert_exception_to_response(mw_instance)
handler_is_async = middleware_is_async
```

That transition is exactly the success case in `SPEC.md`, discharging PO-04 and
preserving `INV` for the next iteration.

## Composition

By induction over `reversed(settings.MIDDLEWARE)`:

1. Initialization establishes `INV`.
2. Each normal iteration either preserves `INV` unchanged on
   `MiddlewareNotUsed` or advances it by exactly one used middleware.
3. Error branches abort before publication.
4. At loop exit, `handler` and `handler_is_async` accurately describe the chain
   made from used middleware only.
5. The final `adapt_method_mode(is_async, handler, handler_is_async)` therefore
   adapts the accurate chain to the requested top-level mode.
6. `_middleware_chain` is assigned only after that final adaptation.

For `is_async=True`, the final chain is async-compatible, discharging PO-06.

## Counterexample eliminated from the pre-fix code

The pre-fix code assigned the adapted wrapper to persistent `handler` before the
factory call. In ASGI mode, a skipped sync-only middleware could convert an
async downstream handler into a synchronous wrapper while leaving
`handler_is_async == True`. A later middleware then received a callable whose
actual mode did not match the loader's metadata. V1 eliminates that path because
the adapted wrapper is never written to persistent state unless the middleware
factory succeeds.

## Adequacy and compatibility

The proof covers the issue's full behavioral surface: skipped middleware,
subsequent middleware, successful middleware, initialization errors, and final
ASGI adaptation. It does not change public APIs or the middleware factory call
shape; compatibility is discharged by PO-07.

## Commands for future machine check

These commands are recorded for a future environment with K available. They were
not run here. They apply after extracting the K-style claims from `SPEC.md`
into the named `.k` files.

```sh
kompile fvk/mini-middleware-loader.k --backend haskell
kast --backend haskell fvk/middleware-loader-spec.k
kprove fvk/middleware-loader-spec.k
```

Expected result: the proof obligations reduce to `#Top`. Until those commands
are run successfully, this remains a constructed proof, not a machine-checked
one.

## Test recommendation

No tests were inspected as authoritative or modified. A future regression test
should cover ASGI middleware loading where a sync-only middleware raises
`MiddlewareNotUsed` before later middleware are loaded. No test deletion is
recommended because the proof was not machine-checked.
