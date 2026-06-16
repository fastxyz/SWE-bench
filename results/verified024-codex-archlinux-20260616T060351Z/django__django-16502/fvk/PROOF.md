# FVK Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were executed.

## Claims

The formal claims are in `fvk/django-head-spec.k` over the mini semantics in
`fvk/mini-wsgi-head.k`.

1. `HEAD write(bytes(N))` preserves `stdoutBytes`.
2. `HEAD sendfile` preserves `stdoutBytes` and does not mark `sendfileUsed`.
3. `HEAD finishHead` preserves `stdoutBytes`, flushes, closes the handler, and
   closes the result.
4. `ConditionalGetMiddleware` adequacy: `GET` and `HEAD` are the safe methods
   admitted to conditional processing; other methods are framed unchanged.

## Proof Sketch

### PO1: HEAD write emits no body bytes

Assume `method = HEAD`, `status = true`, and a chunk `bytes(N)` where `N >= 0`.
There are two cases.

Case `headersSent = false`: V2 executes the `HEAD` branch in `write()`, sets
`bytes_sent = len(data)`, calls `send_headers()`, and calls `_flush()`. It does
not call `_write(data)` for the body. In the mini semantics this is the first
`HEAD write` rule, whose right-hand side keeps `stdoutBytes = OUT`.

Case `headersSent = true`: V2 increments `bytes_sent` and returns without
calling `_write(data)`. In the mini semantics this is the second `HEAD write`
rule, again preserving `stdoutBytes = OUT`.

By case split, all `HEAD write` paths preserve body output bytes.

### PO3: Headers are flushed

In the `headersSent = false` case, `_flush()` happens immediately after
`send_headers()`. In `finish_response()`, `_flush()` also occurs after
`finish_content()`, covering the empty-result path where no chunk reached
`write()`. Therefore the header-only path is not left buffered by the removal
of the normal body write.

### PO4 and PO5: sendfile and finish_response

For `method = HEAD`, V2's `sendfile()` returns `False`, so an optimized file
send cannot be the body-output transition.

For `finish_response()`, V2 delegates all non-`HEAD` methods to `super()`. On
`HEAD`, it enters the custom branch. If the result has a first chunk, the branch
calls `write(first_chunk)` and breaks immediately. By PO1 this does not change
body output. It then calls `finish_content()`, flushes, and closes. If the
result is empty, it skips directly to `finish_content()`, flushes, and closes.
The mini semantics models these as the two `finishHead` rules followed by
`finishContent` and `close`; neither path changes `stdoutBytes`.

Thus `HEAD finish_response()` emits no body and does not drain the full result.

### PO6: Close on abnormal exit

V2 wraps the custom `HEAD finish_response()` body in a cleanup block using
`except BaseException:`. If any abnormal exit occurs inside the custom block,
the handler checks for `self.result.close`, calls it when present, and
re-raises. This discharges the cleanup obligation introduced by replacing
inherited completion logic for `HEAD`.

### PO7: Conditional middleware

V2 changes the method guard from `request.method != "GET"` to
`request.method not in ("GET", "HEAD")`. Therefore `HEAD` reaches the existing
ETag and Last-Modified logic. `set_response_etag()` still only computes ETags
for non-streaming responses with content, so streaming limitations remain
framed by existing behavior. `get_conditional_response()` already treats
`GET` and `HEAD` as methods eligible for `304 Not Modified`.

### PO8: Non-HEAD frame

Each new `ServerHandler` override starts with the non-`HEAD` guard and delegates
to `super()`:

- `write()` delegates for `REQUEST_METHOD != "HEAD"`;
- `sendfile()` delegates for `REQUEST_METHOD != "HEAD"`;
- `finish_response()` delegates for `REQUEST_METHOD != "HEAD"`.

The proof does not claim inherited behavior is correct for all HTTP cases; it
only proves V2 does not change those paths.

## Machine-Check Commands

These commands are emitted for later use and were not run:

```sh
kompile fvk/mini-wsgi-head.k --backend haskell
kast --backend haskell fvk/django-head-spec.k
kprove fvk/django-head-spec.k
```

Expected result after syntax adaptation to a full K setup: `#Top` for all
claims.

## Residual Risk

- This is a partial-correctness proof over a mini WSGI fragment, not a full
  Python or full HTTP server proof.
- Termination of arbitrary response iterators is not proved; V2 reduces that
  risk by advancing at most one chunk for `HEAD`.
- The proof is constructed only; test removal is not recommended without an
  actual `kprove` result.
