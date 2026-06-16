# Baseline Notes

## Root cause

`BaseHandler.load_middleware()` adapted the current `handler` in place before
calling each middleware factory. If that factory raised `MiddlewareNotUsed`, the
loop skipped the middleware but kept the adapted `handler` while leaving
`handler_is_async` unchanged. In ASGI mode this could leave the remaining
middleware chain with a synchronous wrapper even though the loader still treated
the handler as asynchronous. A later synchronous middleware could then return an
`HttpResponse` where the ASGI response path expected an awaitable, producing
errors such as `TypeError: object HttpResponse can't be used in 'await'
expression`.

## Changed files

`repo/django/core/handlers/base.py`

Changed middleware loading so the adapted callable is stored in a temporary
`adapted_handler` variable and passed to the middleware factory. The persistent
`handler` chain is now updated only after the middleware factory succeeds and the
middleware is actually installed. This preserves the previous chain state when a
middleware opts out with `MiddlewareNotUsed`.

## Assumptions and rejected alternatives

I assumed that `MiddlewareNotUsed` means the middleware should have no effect on
the resulting chain, including no sync/async adaptation side effects. That
matches the existing `continue` behavior and the purpose of allowing middleware
to opt out during initialization.

I rejected changing ASGI response handling to tolerate synchronous middleware
responses in this path because the bug is introduced earlier, while constructing
the chain. Adjusting response handling would mask the poisoned chain state
rather than preserving the middleware loader's sync/async invariants.

I also rejected changing middleware capability detection or requiring opt-out
middleware to declare async support. The existing `sync_capable` and
`async_capable` flags already allow Django to adapt middleware for ASGI; the
failure was that an unused middleware's adaptation leaked into the next
middleware.
