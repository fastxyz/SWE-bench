# Code review findings — django__django-14011 (V1 fix)

Scope reviewed:
- `django/core/servers/basehttp.py` — `ThreadedWSGIServer` (`__init__`,
  `process_request_thread`, `_close_connections`, `close_request`) and the new
  `from django.db import connections` import.
- `django/test/testcases.py` — `LiveServerThread.run()` and
  `LiveServerThread._create_server()`.

Each finding is numbered and labelled with a severity:
`[OK]` confirmed correct, `[CONSIDERED]` a real trade-off that was weighed,
`[NIT]` minor/stylistic, `[RISK]` a residual risk that is out of scope.

---

## 1. [OK] The leak fix is at the correct layer

The issue is that `ThreadingMixIn` spawns one thread per request
(`process_request_thread`) and those threads never close the DB connections they
opened, so connections survive into `destroy_test_db()`.

I verified the existing signal-based cleanup is *insufficient* and that
`close_request` is the right place:
- `django/db/__init__.py` connects `close_old_connections` to
  `request_started`/`request_finished`. That handler calls
  `close_if_unusable_or_obsolete()` (`base/base.py:502`), which only closes when
  `get_autocommit()` drifted, after errors, or when `CONN_MAX_AGE` has elapsed
  (`close_at`). With persistent connections (`CONN_MAX_AGE > 0`) it deliberately
  keeps the connection open — but in the threaded server that connection is
  stranded in a soon-dead worker thread, i.e. leaked. It also depends on
  `request_finished` actually firing (it is not sent on every error path).
- V1's `ThreadedWSGIServer.close_request()` → `_close_connections()` →
  `connections.close_all()` runs unconditionally for every request, regardless of
  `CONN_MAX_AGE` and regardless of whether `request_finished` fired. This is
  strictly more robust and directly matches the fix accepted on the ticket.

`close_request` is invoked from `shutdown_request`, which `ThreadingMixIn`
.process_request_thread calls in its `finally`, so closing happens in the worker
thread (where the connections are thread-local) and even when the request raised.
**Confirmed correct.**

## 2. [OK] In-memory SQLite thread-sharing is correctly restored

`LiveServerThread.run()` copies the main thread's connections into its own
thread-local storage, but with `ThreadingMixIn` the request is served in a
*different* (worker) thread, so the override never reached the code that touches
the DB. V1 adds the same copy inside `ThreadedWSGIServer.process_request_thread`,
before delegating to `super().process_request_thread()` (which runs
`finish_request` → WSGI app → DB access). Ordering verified: the override is set
before any DB access. **Confirmed correct.**

## 3. [OK] Closing a shared in-memory connection is safe

In the in-memory case `close_all()` ends up calling `close()` on the *shared*
connection. Verified this is harmless:
- `sqlite3/base.py:270` `close()` skips the real close for in-memory DBs
  (`if not self.is_in_memory_db(): BaseDatabaseWrapper.close(self)`), so the DB
  is not destroyed.
- The `validate_thread_sharing()` guard at the top of `close()` passes because
  `LiveServerTestCase.setUpClass()` already called `inc_thread_sharing()` on that
  connection (`testcases.py:1564`), so `allow_thread_sharing` is True for the
  duration of the test. **Confirmed correct.**

## 4. [OK] `connections` storage is genuinely thread-local

`ConnectionHandler._connections = Local(self.thread_critical)`
(`utils/connection.py:41`) with `thread_critical = True` for DB connections
(`db/utils.py:141`). `__setitem__`/`__getitem__` read/write per-thread attributes,
and `close_all()` iterates the current thread's connections only
(`db/utils.py:207`). So both the per-thread override (Finding 2) and the
per-thread close (Finding 1) operate on the correct thread's storage. **Confirmed.**

## 5. [OK] Double close via the `request_finished` signal is harmless

When a request finishes, both `close_old_connections` (signal) and V1's
`close_request` may close the same connection. `BaseDatabaseWrapper.close()`
early-returns when `self.connection is None` (`base/base.py:291`), so the second
close is a no-op. **No defect.**

## 6. [OK] No circular import / import-time side effects from the new import

`from django.db import connections` was added to `basehttp.py`. Verified
`django.db.__init__` only imports `django.core.signals` (trivial `Signal`
definitions), `django.db.utils`, and `django.utils.connection`; none import
`django.core.servers.basehttp` (grep returned no matches). Importing `connections`
only binds the lazy `ConnectionHandler` singleton — no settings access, no DB
connection at import time. `basehttp` is only imported after Django setup
(runserver / testcases). **Safe.**

## 7. [OK] Change is correctly scoped — `runserver` is unaffected

`basehttp.run()` (used by `runserver`) builds its own threaded class via
`type('WSGIServer', (socketserver.ThreadingMixIn, server_cls), {})` and never
instantiates `ThreadedWSGIServer`. The only user of `ThreadedWSGIServer` is
`LiveServerThread.server_class`. So the new `close_request`/`process_request_thread`
behavior applies to the live-test server only, as intended by the ticket. **Confirmed.**

## 8. [OK] Backward-compatible for existing/direct instantiation of the server

`__init__(self, *args, connections_override=None, **kwargs)` keeps
`connections_override` keyword-only with a default of `None`. Any existing
construction `ThreadedWSGIServer((host, port), Handler, ...)` still works, and the
parameter is consumed before `super().__init__()` so it is not forwarded to
`WSGIServer`/`TCPServer`. With `connections_override=None`,
`process_request_thread` skips the override (`if self.connections_override:`),
preserving behavior for non-live-server users. **Confirmed.**

## 9. [CONSIDERED] `_create_server()` signature change can break a private-method override

V1 changed `LiveServerThread._create_server(self)` to
`_create_server(self, connections_override=None)` and `run()` now calls it as
`self._create_server(connections_override=self.connections_override)`. A subclass
that overrides `_create_server(self)` with no parameter (exactly the workaround
shown in the issue body) would now raise `TypeError`.

Weighed two designs:
- (A, V1) constructor injection via `_create_server(..., connections_override=...)`.
- (B) keep `_create_server(self)` unchanged and set
  `self.httpd.connections_override = self.connections_override` in `run()` after
  construction.

Decision: keep (A). Rationale: `_create_server` is a private (`_`-prefixed)
method; the documented/supported customization hook for the server is the
`server_class` class attribute, added precisely for this in #32416 and referenced
in the issue. Constructor injection is cleaner, fully initializes the server
before `serve_forever()`, and is the form a unit test would naturally exercise
(`thread._create_server(connections_override=...).connections_override`). The only
code broken is a temporary, private-method workaround that the fix itself makes
unnecessary. **Trade-off accepted; V1 stands on this point.**

## 10. [CONSIDERED] `_close_connections()` indirection

`close_request` delegates to `_close_connections()` (which calls
`connections.close_all()`) rather than calling `close_all()` inline. The extra
method is a deliberate, low-cost seam: it lets a test assert/replace the close
without monkeypatching the global `connections.close_all`, while still funnelling
through `connections.close_all()` so tests that *do* patch the global still work.
The comment `# Used for mocking in tests.` documents intent and is consistent with
Django's own conventions. **Kept.**

## 11. [RISK] Daemon-thread shutdown race + `dec_thread_sharing` (pre-existing, out of scope)

`ThreadedWSGIServer.daemon_threads = True`, so `ThreadingMixIn.server_close()`
does not join worker threads. If a request were still in flight when
`LiveServerTestCase` tears down, that worker could run `close_request` →
`close_all()` on the shared in-memory connection *after*
`_tearDownClassInternal()` has called `dec_thread_sharing()`, at which point
`validate_thread_sharing()` would raise inside the daemon thread.

Assessment: this requires a request to be in flight during teardown, which
well-behaved tests avoid (they wait for responses before tearing down); the
exception would be confined to (and logged by) the daemon worker thread and would
not fail the test; and it only affects in-memory SQLite. Eliminating it would mean
flipping `daemon_threads` to `False` (joining workers on close), which changes the
intentional fast-shutdown semantics the original code chose and risks hangs.
**Out of scope for this ticket; not materially worsened by the fix; left as-is.**

## 12. [CONSIDERED] `close_request` is not exception-guarded around the socket close

If `connections.close_all()` raised, `super().close_request(request)` (the socket
close) would be skipped. This matches the simple form accepted on the ticket. A
backend `close()` raising is very unlikely here (connections are either created in
the same worker thread or are share-enabled), and adding a `try/finally` would
diverge from the accepted form and risk masking real errors. **Left as-is.**

## 13. [OK] Retaining the override in `LiveServerThread.run()` is harmless

`run()` still copies `connections_override` into the `LiveServerThread`'s own
thread before `serve_forever()`. That thread does not serve requests (worker
threads do), so the copy is largely redundant now, but it is harmless: for
in-memory SQLite the eventual `finally: connections.close_all()` is a no-op close,
and for other backends `connections_override` is empty. Removing it would be a
behavior change with no benefit and some regression risk, so it is kept. **OK.**

## 14. [OK] MRO / `super()` resolution

`ThreadedWSGIServer(ThreadingMixIn, WSGIServer)`:
- `super().process_request_thread(...)` resolves to
  `ThreadingMixIn.process_request_thread` (present in all supported CPython 3.8+).
- `super().close_request(...)` resolves past `ThreadingMixIn`/`WSGIServer` to
  `socketserver.TCPServer.close_request`.
Both calls are valid. **Confirmed.**

---

## Conclusion

The V1 fix is correct and complete for the issue as described (Findings 1–8, 13,
14). The remaining items are either deliberate, justified trade-offs (Findings 9,
10, 12) or a pre-existing, out-of-scope residual race not worsened by the fix
(Finding 11). No functional change is warranted; V1 is confirmed to stand.
