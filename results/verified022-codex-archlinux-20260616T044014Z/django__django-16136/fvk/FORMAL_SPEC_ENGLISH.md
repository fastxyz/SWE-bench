# Formal Spec in English

Status: constructed, not machine-checked.

## Claim `ASYNC-NOT-ALLOWED-AWAITABLE`

For an async view whose requested method is unsupported, dispatching to
`http_method_not_allowed()` returns an awaitable value that captures a 405
`HttpResponseNotAllowed` response with the allowed-methods header.

## Claim `ASYNC-NOT-ALLOWED-AWAIT`

Awaiting the async fallback value yields the captured 405 response. It does not
raise the pre-V1 `TypeError` caused by awaiting a plain response.

## Claim `SYNC-NOT-ALLOWED-DIRECT`

For a sync view whose requested method is unsupported, dispatching to
`http_method_not_allowed()` returns the 405 response directly.

## Claim `ALLOW-HEADER-PRESERVED`

The response used by both fallback branches is constructed from
`HttpResponseNotAllowed(self._allowed_methods())`, so the allowed methods are
not changed by the async wrapping.

## Claim `OPTIONS-PARITY`

The sync/async result shape of `http_method_not_allowed()` matches the existing
`options()` pattern: direct response for sync views and awaitable response for
async views.

## Frame claim `SUPPORTED-DISPATCH-FRAME`

Supported HTTP method dispatch is unchanged because V1 edits only the fallback
method body.

## Compatibility claim `PUBLIC-COMPAT-FRAME`

The public method signature and virtual dispatch call shape are unchanged.
