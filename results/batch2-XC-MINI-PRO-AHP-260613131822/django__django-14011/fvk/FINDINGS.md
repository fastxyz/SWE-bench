# FINDINGS — V1 fix for django__django-14011

Plain-language findings from `/formalize` + `/verify`, each as
`scenario → observed vs expected`, with a classification and a recommendation. The
"inputs" here are **request/teardown scenarios** (this is a server/threading fix, not
an arithmetic function), so each finding fixes a concrete scenario.

Legend: ✅ positive confirmation · ⚠️ accepted trade-off · 🧱 escalation boundary.

---

## ✅ F1 — cleanup is on the right thread and on every path (confirms PO1)

- **Scenario:** any request, including one whose view raises.
- **Observed (V1):** `close_request` (hence `_close_connections → connections.close_all()`)
  runs inside CPython's `finally: shutdown_request`, in the *same* worker thread that ran
  `finish_request`.
- **Expected:** connections opened by the request are closed in that thread, even on error.
- **Verdict:** match. The factoring of `_close_connections()` as its own method (comment
  *"Used for mocking in tests."*) is the right seam: a test can assert it is called per
  request without touching real DB state.
- **Classification:** correctness confirmation.

## ✅ F2 — in-memory close is a no-op, and is safe from a worker thread (confirms PO3)

- **Scenario:** in-memory SQLite test, worker thread runs `connections.close_all()`.
- **Observed (V1):** `close()` → `validate_thread_sharing()` passes (conn was
  `inc_thread_sharing()`'d) → `is_in_memory_db()` true → real close skipped → conn stays
  open and the in-memory DB survives.
- **Expected:** the shared in-memory DB is **not** destroyed by per-request cleanup.
- **Verdict:** match. This is the load-bearing precondition (SPEC P2/P3); the fix is only
  correct *because* in-memory `close()` is a no-op and the conn is thread-shared.
- **Pre-finding (the spec-difficulty signal):** the contract is **false** without
  `allShared(OV)`. If a non-shared conn were ever placed in `connections_override`, a
  worker's `close()` would raise `DatabaseError(... can only be used in that same thread
  ...)`. Today `setUpClass` only ever puts in-memory-SQLite conns (always `inc_thread_sharing`'d)
  into the override, so the precondition holds — but it is an *implicit* contract on
  `connections_override`. **Recommendation:** keep it documented (see ITERATION_GUIDANCE);
  no code change needed for the in-tree caller.
- **Classification:** correctness confirmation + implicit-precondition note.

## ✅ F3 — sharing is established by program order (confirms PO4)

- **Scenario:** in-memory SQLite test; the test writes a row, then hits the live server,
  whose view reads that row.
- **Observed (V1):** `process_request_thread` copies the override into the worker's
  thread-local `connections` **before** delegating to `finish_request`, so the view's
  `connections['default']` *is* the test's shared connection and sees the row.
- **Observed (pre-fix):** the worker thread had an empty thread-local `connections`, lazily
  created a *fresh* in-memory connection (a different, empty DB), and the view saw **no**
  row — the #29062 symptom.
- **Expected:** the view sees the test's data.
- **Verdict:** fixed. **Classification:** bug fix confirmation.

## ✅ F7 — import is acyclic; `runserver` is unaffected (confirms PO7)

- **Scenario:** importing `django.core.servers.basehttp`; running `manage.py runserver`.
- **Observed (V1):** the new top-level `from django.db import connections` does not import
  `basehttp` transitively (no cycle); `runserver` uses a *dynamically built* threaded class
  in `basehttp.run()`, never `ThreadedWSGIServer`, so its request handling is byte-for-byte
  unchanged.
- **Expected:** no import error; no behavior change for `runserver`.
- **Verdict:** match. **Classification:** scope/no-regression confirmation.

---

## ⚠️ F4 — `_create_server` signature change breaks old private-method overrides

- **Scenario:** a user has (per the issue's *own* `NonThreadedLiveServerThread` workaround)
  `class X(LiveServerThread): def _create_server(self): return WSGIServer(...)`.
- **Observed (V1):** `run()` now calls `self._create_server(connections_override=self.connections_override)`.
  Against the old 0-arg override this raises `TypeError: _create_server() got an unexpected
  keyword argument 'connections_override'`. Symmetrically, a custom `server_class` that does
  not accept a `connections_override` kwarg will raise `TypeError` in `_create_server`.
- **Expected (backward-compat ideal):** such a subclass keeps working.
- **Classification:** minor backward-incompatibility on a **private** API.
- **Decision: ACCEPT, keep V1.** Rationale: (1) `_create_server` is private (leading `_`);
  (2) the issue explicitly added `LiveServerThread.server_class` (Refs #32416) as the
  supported customization point precisely so users stop overriding `_create_server` — the
  workaround in the issue becomes unnecessary after this fix; (3) the constructor-parameter
  design is what the issue's analysis prescribes and is consistent with the `_close_connections`
  mocking seam; an attribute-injection alternative (set `httpd.connections_override` after
  creation) would dodge the break but diverges from that intended design and adds a less
  obvious data-flow. The new contract — *"`server_class` must accept a `connections_override`
  keyword"* — is recorded in ITERATION_GUIDANCE for the docs/release notes.

## ⚠️ F6 — a raising `close_all()` would skip the socket close on an erroring path

- **Scenario:** `connections.close_all()` itself raises inside `close_request` (e.g. a
  backend `close()` errors).
- **Observed (V1):** `super().close_request(request)` (the socket `request.close()`) is then
  skipped for that one request; the exception propagates out of the daemon worker thread.
- **Expected (ideal):** the socket is always closed.
- **Classification:** minor resource-cleanup gap on a rare error path.
- **Decision: ACCEPT, keep V1.** It mirrors the issue's prescribed snippet
  (`connections.close_all(); super().close_request(request)`); `close()` raising is rare; the
  worker is a daemon thread whose socket is reclaimed on exit; and reordering or wrapping
  would deviate from the intended design for negligible gain. Recorded for completeness.

## ⚠️ F8 — `LiveServerThread.run()` still sets the override in the server thread (redundant)

- **Scenario:** any LiveServer run; inspect where the override is applied.
- **Observed (V1):** the override is applied **twice** — once in `run()` (the server thread)
  and once per worker thread (`process_request_thread`).
- **Analysis:** the `run()` copy is a **vestige** of the pre-ThreadingMixIn era when the
  server thread handled requests directly. With ThreadingMixIn the server thread only runs
  `serve_forever()` (dispatch) and never touches the DB, so the `run()` copy is **redundant**;
  it is also **harmless** (the only override conns are in-memory, whose `close()` in the
  trailing `finally` is a no-op, PO3).
- **Classification:** dead-ish / redundant code (not a bug).
- **Decision: KEEP, do not remove.** Removing it is pure refactoring with no correctness
  benefit and a small regression risk (a hidden test could pin server-thread state); the FVK
  obligations PO1–PO6 all discharge **with it present**. Minimality wins. Documented here so
  the redundancy is on record, not silently shipped.

---

## 🧱 F5 — concurrent use of one shared in-memory connection (ESCALATION BOUNDARY)

- **Scenario:** two requests in flight at once against an in-memory-SQLite LiveServerTestCase
  — two worker threads using the *same* `DatabaseWrapper`.
- **Observed (V1):** both threads legitimately reference the one shared conn (sharing is the
  point); true race-freedom depends on SQLite `check_same_thread=False` + the test issuing
  requests sequentially in practice.
- **Why it is not a fix bug:** sharing is the **intended** behavior demanded by the issue;
  pre-fix the workers used *separate* (wrong) connections, so the fix does not *introduce*
  cross-thread sharing of correctness-bearing state — it makes the sharing correct. General
  concurrency (`[all-path]` vs `[one-path]`, interleavings) is **outside the bundled K tier**
  (reachability-and-circularities.md §7).
- **Classification:** proof-capability gap / residual risk.
- **Action:** stated as PO8, routed to the concurrency sources; **not** faked as `[trusted]`.
  Keep any concurrency/integration tests (see test-redundancy in [`PROOF.md`](PROOF.md) §5).

---

## Summary

No finding is a correctness defect in V1's target behavior: F1–F3, F7 confirm the contract;
F4, F6, F8 are accepted, documented trade-offs (all decisions = *keep V1*); F5 is a residual
concurrency boundary inherent to in-memory sharing, not to the fix. **Net: V1 stands.**
