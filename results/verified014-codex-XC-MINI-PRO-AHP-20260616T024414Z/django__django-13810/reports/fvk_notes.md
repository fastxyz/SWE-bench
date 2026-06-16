# FVK Notes

## Decision summary

V1 stands unchanged. The FVK audit found the same operative defect as the
baseline analysis and confirmed that the local `adapted_handler` variable
discharges the required frame condition for `MiddlewareNotUsed`.

## Trace from findings and proof obligations

F-001 identifies the pre-fix code bug: a skipped sync-only middleware in ASGI
mode could overwrite the persistent `handler` while leaving
`handler_is_async` stale. PO-03 states the required frame condition for that
path. V1 satisfies PO-03 because `adapt_method_mode()` now writes only to local
`adapted_handler`, and `continue` happens before any persistent chain update.

F-002 checks that V1 did not weaken the successful middleware path. PO-04
requires the middleware factory to receive the adapted callable and the
persistent chain to advance only after a middleware instance is returned. V1
keeps that behavior: the factory receives `adapted_handler`, then `handler` is
updated to `convert_exception_to_response(mw_instance)`.

F-003 checks branches outside the reported bug. PO-05 requires invalid
capabilities and `None` factory returns to abort before publishing
`_middleware_chain`. V1 does not alter those branches, so no source edit is
needed there.

PO-02 and PO-06 connect the local skip-frame fix to the ASGI symptom. Once
`MiddlewareNotUsed` preserves `(handler, handler_is_async)`, the loop invariant
holds for later middleware and the final top-level adaptation receives accurate
mode metadata. That addresses the reported `HttpResponse`-awaiting failure
without changing ASGI response handling.

PO-07 confirms public compatibility. The only production change remains a local
variable inside `load_middleware()`. No public signature, middleware factory
calling convention, setting, exception type, or hook-list contract changes.

F-004 and PO-08 record the proof limitation: this is a constructed proof over an
abstract mini semantics, not a machine-checked proof. Per the task constraints,
no `kompile`, `kast`, `kprove`, Python, or tests were run.

F-005 records recommended regression coverage only. Test files are fixed and
hidden for this task, so no test file was modified.

## Alternative interpretations rejected

I rejected changing `get_response_async()` to tolerate synchronous `HttpResponse`
returns because F-001 localizes the bug to middleware-chain construction, not to
response sending. Changing ASGI response handling would mask the inconsistent
`handler`/`handler_is_async` state instead of preserving PO-02 and PO-03.

I rejected suppressing or moving the adaptation call itself because a middleware
factory still needs to receive a callable adapted to its selected sync/async
mode. The required change is only to prevent the temporary adapted callable from
becoming persistent when the middleware opts out.
