# PROOF OBLIGATIONS — V1 fix for django__django-14011

Each obligation traces to a contract clause in [`SPEC.md`](SPEC.md) §2 and to the
code under `repo/`. Status: **DISCHARGED** (constructed argument, see
[`PROOF.md`](PROOF.md)), **DISCHARGED (trivial)**, or **ESCALATION BOUNDARY** (stated,
routed to sources, not faked as trusted).

| PO | Statement | Maps to | Status |
|---|---|---|---|
| PO1 | Every worker thread runs `connections.close_all()` in its own thread, even on request error. | C1 | DISCHARGED |
| PO2 | After `closeAll`, no `openLocal` remains in the worker thread's connections. | C1, C3 | DISCHARGED (via `(CLOSEALL)`) |
| PO3 | `closeAll` does not destroy a shared (`openShared`) connection. | C2-preserve | DISCHARGED |
| PO4 | A worker thread serving a request uses the override connection objects, not fresh ones. | C2-share | DISCHARGED |
| PO5 | With `connections_override = None`/empty, no override is applied and connections are still closed. | C4 | DISCHARGED (trivial) |
| PO6 | At server shutdown, the union (worker threads ∪ server thread) leaves no open non-shared connection ⇒ `destroy_test_db()` succeeds. | C1 (end-to-end) | DISCHARGED |
| PO7 | `from django.db import connections` in `basehttp.py` does not create an import cycle and does not regress `runserver`. | P5 | DISCHARGED (static) |
| PO8 | Concurrent worker threads sharing one in-memory connection are race-free. | (residual) | **ESCALATION BOUNDARY** |

---

### PO1 — cleanup actually runs, in the right thread, on every path

`ThreadingMixIn.process_request_thread` is `try: finish_request(...) except: handle_error(...)
finally: shutdown_request(request)`, and `TCPServer.shutdown_request → close_request`.
V1 overrides `close_request` to call `_close_connections()` (→ `connections.close_all()`)
then `super().close_request()`. Because the call sits under CPython's `finally`, it runs
whether the request succeeds or raises (P1). Because `process_request_thread` *is* the
worker thread's target, both `finish_request` and `close_request` execute in that same
thread, so `close_all()` (which is thread-local, P4) closes exactly the connections that
request opened. **Discharged.**

### PO2 — no leaked thread-local connection

Formally: `(CLOSEALL)` proves `closeAll` rewrites `<own>=L` to `<closed>=closeList(L)`,
and `(PRT)` instantiates `L = OV mkLocals(N)`, giving final `closeList(OV) mkClosed(N)`.
`close(openLocal)=closed`, so `mkClosed(N)` has only `closed`; `close(openShared)=openShared`
and `allShared(OV)` (P3) keeps `OV` shared — neither contributes an `openLocal`. Hence the
post-state has **zero** `openLocal`. Mapping back: every non-shared DB connection the
request opened is closed before the worker thread exits (**C1, C3**). **Discharged** (proof
in [`PROOF.md`](PROOF.md)).

### PO3 — shared connection preserved

In `close()`, the shared connection is in-memory, so `close()` is a no-op (P2):
`close(openShared)=openShared`. `validate_thread_sharing()` (called first inside `close()`)
passes because the conn was `inc_thread_sharing()`'d (P3). So `closeAll` leaves every `OV`
entry `openShared` and never raises. Cross-check on the real code: the worker thread's
`request_finished` signal also calls `close_old_connections → close_if_unusable_or_obsolete
→ self.close()`, equally a no-op for in-memory (P6). **Discharged.**

### PO4 — the request sees the shared connection (sharing)

By program order in `process_request_thread`: V1 runs the `connections[alias]=conn` loop
**before** `super().process_request_thread()` (= `finish_request`). In mini-X this is the
Transitivity step `setOverride` *then* `handleRequest`: when `handleRequest` runs, `OV` is
already in `<own>`, so the request reuses it rather than creating an `openLocal` for that
alias. On the real `connections` Local, `connections[alias]=conn` makes a subsequent
`connections[alias]` lookup in that thread return `conn` (P4). **Discharged.**

### PO5 — graceful no-override

`process_request_thread` guards with `if self.connections_override:`; `None` and `{}` are
both falsy ⇒ the override loop is skipped, no entry is added, and `close_request →
_close_connections` still runs (PO1). In mini-X this is `(PRT)` at `OV=.List, N` arbitrary:
post `<closed> = closeList(.List) mkClosed(N) = mkClosed(N)` — still no `openLocal`.
**Discharged (trivial).**

### PO6 — end-to-end teardown

The set of all connections at teardown = (⋃ worker threads' connections) ∪ (server thread's
connections). Worker threads: closed by PO1/PO2. Server thread (`LiveServerThread.run`): its
`finally: connections.close_all()` closes any connection created in that thread; the only
override conns there are in-memory (no-op close, PO3). Hence no open *non-shared* connection
survives, and `destroy_test_db()` (which the in-memory shared conns don't block — they live
in the test process and are torn down via `dec_thread_sharing()` in
`_tearDownClassInternal`) no longer hits "being accessed by other users". **Discharged.**

### PO7 — import safety, no `runserver` regression

Static: `django/db/__init__.py` imports `django.core.signals`, `django.db.utils`,
`django.utils.connection` only — none import `django.core.servers.basehttp`, so the new
top-level `from django.db import connections` is acyclic (P5). `runserver` builds its server
with `type('WSGIServer', (ThreadingMixIn, server_cls), {})` in `basehttp.run()` — it does
**not** instantiate `ThreadedWSGIServer`, so the added `__init__`/`close_request`/
`process_request_thread` never affect `runserver`. **Discharged (static).**

### PO8 — concurrency of the shared connection — ESCALATION BOUNDARY

ThreadingMixIn may run several worker threads at once; with in-memory SQLite they share a
single `DatabaseWrapper`/sqlite3 connection. Whether concurrent use is race-free depends on
SQLite's `check_same_thread=False` semantics and the test issuing requests sequentially —
genuine concurrency / `[all-path]`-vs-`[one-path]` reasoning that the bundled K tier does
**not** cover (fvk_materials/knowledge/reachability-and-circularities.md §7). This is **not**
introduced by the fix (sharing is the *intended* design from the issue; before the fix the
worker simply used a wrong, private connection). Stated as an open obligation, routed to the
concurrency sources; **never admitted as `[trusted]`**. See [`FINDINGS.md`](FINDINGS.md) F5.
