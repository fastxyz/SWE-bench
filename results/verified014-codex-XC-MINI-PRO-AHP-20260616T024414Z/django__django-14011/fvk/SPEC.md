# FVK Spec: django__django-14011

Status: constructed, not machine-checked. No tests, Python code, or K tooling were run.

## Scope

Audited production unit:

- `django.core.servers.basehttp.ThreadedWSGIServer.close_request()`

Relevant call path from public issue evidence:

- `ThreadingMixIn.process_request_thread()` handles a request in a worker thread.
- Its `finally` block calls `shutdown_request(request)`.
- `shutdown_request()` calls `close_request(request)`.

The formal model is intentionally small. It tracks only the properties affected by the issue and the V2 patch:

- `dbOpen`: the number of open database connections visible through Django's current-thread connection storage.
- `requestClosed`: whether inherited request/socket cleanup has run.
- `closeAllOutcome`: whether `connections.close_all()` returns normally or raises.
- `exception`: whether a DB-close exception is propagated after finalization.

Formal core:

- `fvk/mini-close-request.k`
- `fvk/threaded-wsgi-server-spec.k`

## Intent Spec

I1. Each `ThreadedWSGIServer` request worker must close the Django database connections that belong to that worker thread before the worker finishes request cleanup.

I2. The cleanup must happen from `close_request()`, the hook reached by `ThreadingMixIn.process_request_thread()` through `shutdown_request()`.

I3. The override must preserve the inherited request cleanup behavior of `socketserver.TCPServer.close_request()`, which closes the individual request/socket.

I4. Threaded live-server behavior must remain available. Replacing `ThreadedWSGIServer` with non-threaded `WSGIServer` is not an acceptable fix because public tests and issue context depend on threaded nested requests.

I5. The SQLite in-memory thread-sharing question mentioned in the issue notes is related but separate. The accepted issue text identifies the DB-connection leak after request threads as the target, and notes the SQLite sharing concern as previously reported elsewhere.

## Public Evidence Ledger

E1. Source: `benchmark/PROBLEM.md`

Quoted evidence: "LiveServerTestCase's ThreadedWSGIServer doesn't close database connections after each thread"

Semantic obligation: Postcondition for each request worker: after request cleanup, the worker's Django DB connections are closed.

Status: Encoded by claim C1 and proof obligation PO-1/PO-2.

E2. Source: `benchmark/PROBLEM.md`

Quoted evidence: "ThreadingMixIn creates a new thread for each request, but those threads don't close their database connections at their conclusion"

Semantic obligation: Cleanup must occur in the per-request worker thread, not only in `LiveServerThread.run()`.

Status: Encoded by claim C1 and proof obligation PO-1/PO-2.

E3. Source: `benchmark/PROBLEM.md`

Quoted evidence: "database connections could perhaps be closed inside close_request()"

Semantic obligation: `ThreadedWSGIServer.close_request()` is the intended hook.

Status: Encoded by claim C1 and proof obligation PO-1.

E4. Source: `benchmark/PROBLEM.md`

Quoted evidence: `def close_request(self, request): ... request.close()`

Semantic obligation: The override must preserve individual request/socket cleanup.

Status: Encoded by claim C1/C2 and proof obligation PO-3/PO-4.

E5. Source: `repo/django/test/testcases.py`

Quoted evidence: `finally: connections.close_all()` in `LiveServerThread.run()`

Semantic obligation: Existing Django live-server cleanup closes connections for the live server thread, supporting the analogy that request threads need their own same-thread cleanup.

Status: Implementation evidence for PO-2.

E6. Source: `repo/django/db/utils.py`

Quoted evidence: `def close_all(self): ... connection = getattr(self._connections, alias) ... connection.close()`

Semantic obligation: Calling `connections.close_all()` from a worker thread closes only connections visible in that thread's connection storage.

Status: Implementation fact used in claim C1.

E7. Source: `repo/tests/servers/tests.py`

Quoted evidence: `class LiveServerThreadedTests ... "If LiveServerTestCase isn't threaded, these tests will hang."`

Semantic obligation: Preserve threaded live-server behavior.

Status: Compatibility obligation PO-5.

E8. Source: `benchmark/PROBLEM.md`

Quoted evidence: "FYI, I see that the lack of the SQLite thread-sharing logic I mentioned above has previously been reported here: #29062"

Semantic obligation: Treat SQLite thread-sharing as a separate concern unless the close-request proof requires it.

Status: Scope boundary PO-6 and finding F3.

## Formal Spec English

C1. Normal cleanup claim: For every request worker state with `N >= 0` open current-thread DB connections and `closeAllOutcome = normal`, executing `close_request` reaches a state with `dbOpen = 0` and `requestClosed = true`.

C2. Exceptional DB-cleanup claim: For every request worker state with `N >= 0` open current-thread DB connections and `closeAllOutcome = dbError`, executing `close_request` still reaches `requestClosed = true` and propagates the DB cleanup exception. The DB-open count is unconstrained in this exceptional case because the failed `close_all()` cannot be proven to close all DB resources.

## Spec Audit

C1 vs I1/I2: pass. The claim directly encodes per-request-thread DB cleanup at `close_request()` on the normal path.

C1 vs I3: pass. The claim includes `requestClosed = true`, so inherited cleanup is not dropped.

C2 vs I3: pass. This claim was added after auditing V1. It captures that the inherited request cleanup is a frame condition even when the new DB cleanup raises.

C2 vs I1: intentionally partial. DB connections are proven closed only when `connections.close_all()` returns normally. If `close_all()` itself raises, the code cannot guarantee all DB connections closed, and the spec does not pretend otherwise.

I4 compatibility: pass. V2 does not replace `ThreadedWSGIServer`, change `server_class`, or change the public method signature.

I5 SQLite sharing: pass as a scope boundary. The issue notes identify it as related and separately reported; V2 does not claim to fix it.

## Public Compatibility Audit

Changed public symbol: `ThreadedWSGIServer.close_request(self, request)` added as an override.

Signature compatibility: pass. The signature matches `socketserver.TCPServer.close_request(self, request)`.

Callsite compatibility: pass. Existing dispatch through `shutdown_request()` calls `close_request(request)` with the same argument shape.

Subclass/override compatibility: pass. No in-repo subclass override of `ThreadedWSGIServer.close_request()` was found. `LiveServerThread.server_class` remains customizable and unchanged.

Behavioral compatibility: pass. V2 preserves the superclass `close_request()` cleanup with `super().close_request(request)` and makes it unconditional with `try/finally`.

Threaded behavior compatibility: pass. `daemon_threads = True` and threaded live-server behavior are unchanged.

## Machine Check Commands

These commands are recorded for later machine checking. They were not run.

```sh
cd fvk
kompile mini-close-request.k --backend haskell
kast --backend haskell threaded-wsgi-server-spec.k
kprove threaded-wsgi-server-spec.k
```
