# Baseline notes — django__django-14011

## Issue

`LiveServerTestCase`'s `ThreadedWSGIServer` does not close database connections
after each request thread. This causes the reappearance of the bug from #22414:
at the end of a test run, `destroy_test_db()` raises
`OperationalError: database "test_..." is being accessed by other users`
because not all database connections have been closed. The failure is a race
condition, so it only appears intermittently.

A secondary, related defect is noted in the issue: the per-request worker threads
created by `ThreadingMixIn` do not perform the SQLite in-memory thread-sharing
that `LiveServerThread.run()` does, so requests served by the threaded server
would not see the test's in-memory SQLite database.

## Root cause

`ThreadedWSGIServer` mixes in `socketserver.ThreadingMixIn`. For every request,
`ThreadingMixIn.process_request()` spawns a **new thread** whose target is
`process_request_thread()`. That method calls `finish_request()` (which handles
the WSGI request and, as a side effect, opens database connections in the new
thread's thread-local `connections` storage) and finally `shutdown_request()`
(→ `close_request()`).

Two things were missing in this per-request thread lifecycle:

1. **Connections were never closed.** Neither `process_request_thread()` nor
   `close_request()` closed the database connections opened in the worker
   thread. The connections lingered until the (daemon) thread was eventually
   garbage-collected, which races with `destroy_test_db()` at teardown — exactly
   the #22414 symptom.

2. **No thread-sharing for in-memory SQLite.** `LiveServerThread.run()` copies
   the main thread's connections into its own thread-local `connections` (the
   fix from #22414), but those overrides live in the `LiveServerThread` thread,
   **not** in the per-request worker threads where requests are actually served.
   So for in-memory SQLite a worker thread would lazily create a *fresh*
   in-memory database instead of reusing the test's shared connection.

Because `connections` (`ConnectionHandler._connections`) is backed by
`asgiref.local.Local`, it is per-thread; the worker threads start with empty
connection storage, which is why both problems are localized to those threads.

Note: `runserver`'s `basehttp.run()` does **not** use `ThreadedWSGIServer` — it
builds its own dynamic `type('WSGIServer', (ThreadingMixIn, server_cls), {})`
class and relies on the `request_started`/`request_finished` signals for
connection cleanup. So this fix is correctly scoped to the live-test server only
and does not change `runserver` behavior.

## Changes

### `django/core/servers/basehttp.py`
- Added `from django.db import connections` (no circular import: `django.db`
  only pulls in `django.core.signals`, `django.db.utils`, and
  `django.utils.connection`, none of which import `basehttp`).
- Extended `ThreadedWSGIServer`:
  - `__init__(self, *args, connections_override=None, **kwargs)` stores a
    `connections_override` mapping (the parameter is consumed before
    `super().__init__()`, so it is not forwarded to `WSGIServer`/`TCPServer`).
  - `process_request_thread()` override: before delegating to the
    `ThreadingMixIn` implementation, it copies `connections_override` into the
    worker thread's thread-local `connections`. This reproduces, per worker
    thread, the in-memory SQLite thread-sharing that `LiveServerThread.run()`
    performs, fixing problem (2).
  - `_close_connections()` helper (a small seam so tests can mock/assert the
    close) that calls `connections.close_all()`.
  - `close_request()` override that calls `_close_connections()` and then
    `super().close_request(request)`, ensuring every worker thread closes its
    database connections when the request is torn down, fixing problem (1).

  Closing is safe for the shared in-memory SQLite connection:
  `SQLiteDatabaseWrapper.close()` is a no-op for in-memory databases (it skips
  the real close to avoid destroying the DB), and `validate_thread_sharing()`
  passes because `LiveServerTestCase.setUpClass()` has already called
  `inc_thread_sharing()` on that connection.

### `django/test/testcases.py`
- `LiveServerThread.run()` now passes `connections_override=self.connections_override`
  to `_create_server()` so the server can apply the overrides inside its worker
  threads. The existing override of the `LiveServerThread`'s own thread-local
  connections is kept (harmless; that thread runs `serve_forever()` and does not
  serve requests directly).
- `LiveServerThread._create_server(self, connections_override=None)` now accepts
  and forwards `connections_override` to `self.server_class(...)`.

## Assumptions / alternatives considered

- **Where to close connections.** The issue suggests overriding `close_request()`
  with `connections.close_all()`. I used that, but routed the call through a
  tiny `_close_connections()` method to provide a stable, mockable seam (the
  comment documents this intent) without changing behavior. An alternative was
  closing inside `process_request_thread`'s `finally`; `close_request()` is the
  documented override point in CPython's `socketserver` and keeps the change
  minimal, so I preferred it.

- **Where to apply the SQLite override.** I put the per-thread override in
  `process_request_thread()` (which is the worker thread's entry point) rather
  than in `finish_request()` or the request handler, so it runs exactly once per
  worker thread, before any DB access, mirroring `LiveServerThread.run()`.

- **Passing the overrides to the server.** I added a `connections_override`
  constructor argument (consistent with how `LiveServerThread` already receives
  it) rather than mutating a global or reaching back into the thread. This keeps
  `ThreadedWSGIServer` self-contained and lets the existing
  `server_class`/`server_thread_class` customization hooks keep working.

- **Not touching `runserver`.** Confirmed `basehttp.run()` builds its own
  threaded class and is unaffected, so I deliberately left it alone to avoid an
  unrelated behavior change.

- **Keeping vs. removing the override in `LiveServerThread.run()`.** I kept it
  for minimality and safety; it is redundant with the per-worker-thread override
  but not harmful (in-memory `close()` is a no-op, and the thread does not serve
  requests).
