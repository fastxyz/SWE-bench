# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Code changes from V1 to V2

Apply one targeted source change:

- In `repo/django/core/servers/basehttp.py`,
  `ServerHandler.finish_response()` should use `except BaseException:` in its
  custom `HEAD` cleanup path so `self.result.close()` is preserved for all
  abnormal exits. This addresses Finding F2 and discharges PO6.

This change has been applied.

## V1 changes retained

Keep V1's server-layer body suppression:

- `write()` sends/flushed headers but does not write body bytes for `HEAD`
  (F1, PO1, PO3).
- `sendfile()` returns `False` for `HEAD` so optimized file paths cannot send a
  body (F3, PO4).
- `finish_response()` only advances far enough to establish headers and then
  closes (F1, PO5).

Keep V1's middleware update:

- `ConditionalGetMiddleware` should process `HEAD` with `GET` for conditional
  response handling (F4, PO7).

## Tests and verification guidance

Do not modify tests in this benchmark. In a normal development environment,
add or keep tests for:

- `runserver`/`ServerHandler` returns no body for `HEAD` on a regular
  `HttpResponse`;
- `HEAD` with `StreamingHttpResponse` does not drain the full iterator;
- `HEAD` with `FileResponse` or `wsgi.file_wrapper` does not use sendfile to
  emit a body;
- `ConditionalGetMiddleware` computes or respects validators for `HEAD`.

Run the emitted K commands only in an environment that permits K tooling:

```sh
kompile fvk/mini-wsgi-head.k --backend haskell
kast --backend haskell fvk/django-head-spec.k
kprove fvk/django-head-spec.k
```

Until then, treat the proof as constructed, not machine-checked.
