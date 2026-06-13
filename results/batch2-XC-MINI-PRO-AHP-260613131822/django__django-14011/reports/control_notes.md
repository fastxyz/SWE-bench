# Control notes — django__django-14011 (V2 review outcome)

## Summary of outcome

After a systematic, skeptical re-review of the V1 fix (recorded in
`review/FINDINGS.md`), **V1 stands unchanged**. No source edits were made in this
pass. The review found the fix correct and complete for the issue as described;
every potentially-debatable point resolved to a deliberate, justified decision to
keep V1 rather than a defect to repair. Each decision below cites the numbered
finding(s) that justify it.

## What V1 does (recap)

- `django/core/servers/basehttp.py`: `ThreadedWSGIServer` gains a
  `connections_override` constructor argument, a `process_request_thread` override
  that injects those connections into each worker thread, and a
  `close_request` → `_close_connections()` → `connections.close_all()` chain that
  closes the worker thread's DB connections after every request. Adds
  `from django.db import connections`.
- `django/test/testcases.py`: `LiveServerThread.run()` passes
  `connections_override` to `_create_server()`, and `_create_server()` accepts and
  forwards it.

## Decisions, traced to findings

1. **Keep the `close_request` → `connections.close_all()` mechanism as the leak
   fix.** Confirmed this is the correct layer: the existing
   `request_finished`/`close_old_connections` signal path is insufficient because
   it honors `CONN_MAX_AGE` (won't drop persistent connections stranded in dead
   worker threads) and depends on the signal firing, whereas `close_request` runs
   unconditionally and even on the request error path.
   → Findings **1**, **5**, **14**.

2. **Keep the `process_request_thread` override for in-memory SQLite
   thread-sharing.** It reinstates, per worker thread and before any DB access,
   the connection sharing that `LiveServerThread.run()` only set up in the
   non-serving thread; and closing the shared in-memory connection afterwards is a
   verified no-op that cannot destroy the DB or trip the thread-sharing guard.
   → Findings **2**, **3**, **4**.

3. **Keep `from django.db import connections` at module top.** Verified there is no
   import cycle and no import-time side effect; `basehttp` is only imported after
   Django setup.
   → Finding **6**.

4. **Make no change to `runserver`.** Confirmed `basehttp.run()` builds its own
   threaded class and never uses `ThreadedWSGIServer`, so the fix is correctly
   scoped to the live-test server and there is no `runserver` regression to guard
   against.
   → Finding **7**.

5. **Keep the keyword-only `connections_override=None` constructor parameter.** It
   is backward-compatible for any existing or direct instantiation of
   `ThreadedWSGIServer` and is consumed before `super().__init__()`.
   → Finding **8**.

6. **Keep the `_create_server(self, connections_override=None)` signature change
   (constructor injection) rather than switching to post-construction attribute
   assignment.** Although this can break a subclass that overrides the *private*
   `_create_server(self)` (the temporary workaround shown in the issue), the
   supported customization hook is the `server_class` class attribute (added in
   #32416 for exactly this purpose). Constructor injection is cleaner, fully
   initializes the server before `serve_forever()`, and is the natural unit-test
   surface. The trade-off was explicitly weighed and accepted.
   → Finding **9**.

7. **Keep the `_close_connections()` seam** (instead of inlining
   `connections.close_all()`), because it is a low-cost, mock-friendly indirection
   that still routes through `connections.close_all()` so global-patch tests also
   work.
   → Finding **10**.

8. **Do not flip `daemon_threads` to `False`.** The only residual issue — a worker
   still in flight during teardown calling `close()` on the shared in-memory
   connection after `dec_thread_sharing()` — requires an abnormal teardown
   ordering, is confined to (and logged by) a daemon thread without failing the
   test, affects only in-memory SQLite, and is pre-existing rather than introduced
   by the fix. Forcing worker joins would change the intentional fast-shutdown
   semantics and risk hangs, so it is out of scope.
   → Finding **11**.

9. **Do not add a `try/finally` around `_close_connections()` in `close_request`.**
   `close_all()` raising is very unlikely in this context, and a guard would
   diverge from the simple accepted form and could mask real errors.
   → Finding **12**.

10. **Leave the existing override copy in `LiveServerThread.run()` in place.** It is
    now largely redundant but harmless; removing it would be a behavior change with
    regression risk and no benefit.
    → Finding **13**.

## Net change in this pass

No code changed. `review/FINDINGS.md` documents the audit; this file records the
rationale. V1 (as described in `reports/baseline_notes.md`) is confirmed.
