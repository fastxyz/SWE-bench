# Baseline Notes

## Root cause

`runserver` uses `django.core.servers.basehttp.ServerHandler`, a subclass of
`wsgiref.simple_server.ServerHandler`, to iterate the WSGI response and write
each body chunk to the socket. Django had removed earlier framework-level body
stripping for `HEAD` responses on the assumption that the WSGI server would
handle it, but this development server path did not. As a result, `HEAD`
requests passed through normal middleware and response generation and then had
their body bytes written to `stdout` just like `GET` requests.

The related conditional middleware still reflected the older assumption that a
`HEAD` response body was unavailable while middleware ran. In this code path the
body is available until the final server/client layer removes it, so skipping
`HEAD` prevented valid conditional response handling and ETag generation.

## Files changed

`repo/django/core/servers/basehttp.py`

- Added `ServerHandler.write()` handling for `HEAD` requests that performs the
  same header/status bookkeeping as `wsgiref` but does not write body bytes to
  the socket. It explicitly flushes after sending headers because the normal
  body write that would flush them is skipped.
- Added `ServerHandler.sendfile()` handling so an optimized file send path
  cannot bypass the `HEAD` body suppression.
- Added `ServerHandler.finish_response()` handling for `HEAD` requests that
  sends headers and then closes the response without streaming the entire body.
  It advances far enough to support WSGI applications that call
  `start_response()` from the first iteration, while avoiding writing or
  draining the full response body.

`repo/django/middleware/http.py`

- Updated `ConditionalGetMiddleware` to treat `HEAD` like `GET` for conditional
  response processing.
- Updated the surrounding comments and docstring to match the current lifecycle:
  middleware can inspect non-streaming response content before the server strips
  the `HEAD` body.

## Assumptions and alternatives considered

- I assumed the correct layer for suppressing `HEAD` bodies is the development
  WSGI server, matching the issue description that external WSGI servers already
  perform this responsibility.
- I considered stripping `response.content` in `WSGIHandler`, but rejected it
  because that would reintroduce application/framework-level mutation of the
  response before middleware and response-closing semantics complete.
- I considered making `write()` alone drop body bytes. That would be enough for
  finite responses, but it would still drain streaming responses and could allow
  a `sendfile()` implementation to transmit a body. The final change also
  covers `finish_response()` and `sendfile()`.
- I did not modify tests, and I did not run tests or project code, in keeping
  with the benchmark instructions.
