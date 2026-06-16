# FVK Spec for django__django-16502

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Intent Spec

1. For every HTTP `HEAD` request handled by Django's development WSGI server,
   response body bytes must not be returned to the client.
2. The body removal responsibility belongs at the WSGI server boundary for
   `runserver`, not in `WSGIHandler` or application middleware.
3. Headers, status, conditional response behavior, response closing, and request
   body draining must continue to behave as they did for ordinary server
   completion, except that body bytes are not written for `HEAD`.
4. Middleware sees the generated response before final server-level `HEAD` body
   stripping, so `ConditionalGetMiddleware` may compute and use validators for
   `HEAD` as it does for `GET`.
5. Non-`HEAD` methods are frame conditions: this fix must not change their body
   write path.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "response bodies must not be returned for HEAD requests" | `HEAD` response body bytes emitted by `runserver` must be zero. | Encoded by PO1 and K claim `write(bytes(N))` with unchanged `stdoutBytes`. |
| E2 | `benchmark/PROBLEM.md` | "letting the server perform the body removal" | The fix belongs in `ServerHandler`, not by mutating `HttpResponse.content` earlier. | Encoded by PO2 and frame condition PO8. |
| E3 | `benchmark/PROBLEM.md` | Broken pipe occurs because compliant clients may stop after headers. | Header-only `HEAD` responses must flush headers and avoid body writes. | Encoded by PO3 and PO5. |
| E4 | `benchmark/PROBLEM.md` hint | "body won't be empty as far as middleware is concerned" | `HEAD` middleware processing can inspect non-streaming body content before server stripping. | Encoded by PO7. |
| E5 | `benchmark/PROBLEM.md` hint | "entity tag validators can still be set for HEAD requests" | `ConditionalGetMiddleware` must not reject `HEAD` solely because it is not `GET`. | Encoded by PO7. |
| E6 | Source: `repo/django/core/servers/basehttp.py` | `ServerHandler` inherits WSGI iteration and has runserver-specific hooks. | Body suppression must cover `write()`, `sendfile()`, and `finish_response()`. | Encoded by PO1, PO4, PO5. |
| E7 | Source: `repo/django/core/servers/basehttp.py` | `close()` drains input and then delegates to inherited close. | Custom `finish_response()` must still close results on normal and abnormal exits. | Encoded by PO6. |
| E8 | Source: `repo/django/middleware/http.py` V1 comment | The old comment said `HEAD` bodies were unavailable in middleware. | The comment and method gate must match the current lifecycle. | Encoded by PO7. |

## Human-Readable Formal Contract

For the modeled `ServerHandler` state:

- `method = HEAD`, `status = true`, and any body chunk `bytes(N)` with
  `N >= 0`:
  - `write(bytes(N))` may set `headersSent`, `bytesSent`, and `flushed`;
  - `stdoutBytes` remains exactly the pre-state value.
- `method = HEAD`:
  - `sendfile` returns the non-send path and leaves `stdoutBytes` unchanged.
- `method = HEAD` and any finite response result:
  - `finishHead` advances at most to the first chunk to establish headers;
  - `stdoutBytes` remains unchanged;
  - headers are flushed;
  - the handler and result are closed.
- `method != HEAD`:
  - body write behavior is delegated to the inherited implementation and is not
    modeled as changed by this fix.
- `ConditionalGetMiddleware`:
  - routes `GET` and `HEAD` responses through ETag/Last-Modified conditional
    processing;
  - returns other methods unchanged.

## Formal Core Files

- `fvk/mini-wsgi-head.k`: mini WSGI server fragment for body writes, sendfile,
  finish, flush, and close state.
- `fvk/django-head-spec.k`: reachability claims with provenance comments.

Suggested commands, not executed:

```sh
kompile fvk/mini-wsgi-head.k --backend haskell
kast --backend haskell fvk/django-head-spec.k
kprove fvk/django-head-spec.k
```

Expected machine-check outcome after syntax adaptation to a full K environment:
`#Top` for all claims.

## Adequacy Audit

The K claims say exactly the public intent requires for this fix: `HEAD` body
output bytes are unchanged while headers/flush/close can proceed. They do not
prove a broader HTTP server, all WSGI semantics, or termination of arbitrary
streaming iterators. The V2 proof includes only partial correctness of the
header/body/close state transition.

Compatibility audit:

- No public method signatures were changed.
- `ServerHandler.write()` retains the WSGI `write(bytes)` callable shape.
- `sendfile()` keeps the same signature and only changes the `HEAD` branch.
- `finish_response()` keeps the same signature and delegates all non-`HEAD`
  requests to the inherited implementation.
- `ConditionalGetMiddleware.process_response()` keeps the same signature and
  broadens safe-method processing from `GET` to `GET`/`HEAD`, matching the
  public hint.
