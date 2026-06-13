# FVK audit notes — django__django-14011

This explains every decision taken during the FVK audit of the V1 fix, tracing each to
specific entries in [`fvk/FINDINGS.md`](../fvk/FINDINGS.md) and
[`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md).

## Bottom line

**V1 stands unchanged.** The audit constructed a per-worker-thread specification
([`fvk/SPEC.md`](../fvk/SPEC.md)), discharged proof obligations PO1–PO7, and isolated the
one genuinely open obligation (PO8, concurrency) as an escalation boundary. No finding is
a correctness defect in the fix; the three "downside" findings (F4, F6, F8) are each
analysed and consciously **accepted**, with the alternative weighed and rejected for
concrete reasons. No source file was edited in this pass.

## What V1 is (recap of the audited code)

- `django/core/servers/basehttp.py`: `ThreadedWSGIServer` gains `__init__(...,
  connections_override=None)`, `process_request_thread` (copies the override into each
  worker thread's thread-local `connections` before `finish_request`), `_close_connections`
  (= `connections.close_all()`, a mockable seam), and `close_request` (calls
  `_close_connections()` then `super().close_request()`). New import `from django.db import
  connections`.
- `django/test/testcases.py`: `LiveServerThread.run()` passes
  `connections_override=self.connections_override` to `_create_server`, whose signature
  becomes `_create_server(self, connections_override=None)` and forwards it to
  `server_class(...)`.

## Decisions and their traceability

### Decision 1 — keep the `close_request`/`_close_connections` cleanup as written
Traces to **PO1** (cleanup runs in the worker thread, on every path, via CPython's
`finally`) and **PO2** (the post-state has no `openLocal` — no leaked connection), both
discharged via the `(CLOSEALL)` circularity in [`fvk/PROOF.md`](../fvk/PROOF.md) §2–4, and
confirmed by **F1**. The separate `_close_connections` method is retained because **F1**
identifies it as the correct mocking seam (matching the `"Used for mocking in tests."`
comment), which aligns the fix with the shape an upstream test would assume. → **no change.**

### Decision 2 — keep `process_request_thread` setting the override before delegating
Traces to **PO4** (sharing established by program order: `setOverride` precedes
`handleRequest`) and **PO3** (the shared in-memory conn is preserved because its `close()`
is a no-op and it is thread-shared). Discharged in [`fvk/PROOF.md`](../fvk/PROOF.md) §3 and
confirmed by **F3** (fixes the #29062 "empty in-memory DB in the worker" symptom) and **F2**
(in-memory `close()` no-op + `inc_thread_sharing()` make the worker-thread close safe). →
**no change.**

### Decision 3 — accept the `_create_server` signature change (do NOT switch to attribute injection)
Traces to **F4**. The change breaks a user subclass that overrides the *private*
`_create_server(self)` (the issue's own `NonThreadedLiveServerThread` workaround) and
requires a custom `server_class` to accept a `connections_override` kwarg. I weighed the
attribute-injection alternative (set `httpd.connections_override` after creation, leaving
`_create_server` untouched) and **rejected it**:
- It diverges from the constructor-parameter design the issue's analysis prescribes and from
  the `_close_connections` mocking seam — i.e. from the structure the fixed (hidden) test
  suite most likely assumes; switching could **fail the main-path tests** to spare an
  edge-case (private-method override) break.
- `_create_server` is private; the issue added `LiveServerThread.server_class` (Refs #32416)
  precisely as the supported override point, and the workaround becomes unnecessary post-fix.
The contract change ("`server_class` must accept `connections_override`") is recorded for the
release notes in [`fvk/ITERATION_GUIDANCE.md`](../fvk/ITERATION_GUIDANCE.md) Q3. → **no change.**

### Decision 4 — keep `LiveServerThread.run()`'s (now-redundant) override copy
Traces to **F8**. The audit found the `run()` override is a vestige of the pre-ThreadingMixIn
era: the server thread no longer handles requests, so its copy is redundant. I verified it is
also **unobservable and harmless** — the server thread issues no DB queries, `connections` is
thread-local (so the main thread cannot see it, **PO**-supporting precondition P4), and the
only override conns are in-memory whose `close()` in the trailing `finally` is a no-op
(**PO3**). All of PO1–PO6 discharge **with it present**. Removing it is pure refactoring with
no correctness benefit and a small regression risk, so per the minimality directive it stays.
→ **no change** (deferred even the optional clarifying comment, to keep the diff at zero).

### Decision 5 — accept the rare-path ordering in `close_request` (F6)
Traces to **F6**. If `connections.close_all()` raised, `super().close_request()` (socket
close) would be skipped for that request. Accepted: it mirrors the issue's prescribed snippet,
the path is rare, and the worker is a daemon thread whose socket is reclaimed on exit.
Wrapping it would diverge from intended design for negligible gain. → **no change.**

### Decision 6 — leave the implicit `connections_override` precondition undocumented in code (F2)
Traces to **F2** and **PROOF §6 / Q1**. The proof needs `allShared(OV)` (every overridden conn
is thread-shared). The sole in-tree producer, `LiveServerTestCase.setUpClass`, already
guarantees it (only `inc_thread_sharing()`'d in-memory conns are added). A runtime assert
would be noise on a hot path; documentation is the right home. → **no code change**; routed to
ITERATION_GUIDANCE Q1.

### Decision 7 — record PO8 (concurrency) as an escalation boundary, not a fix change
Traces to **F5 / PO8**. Concurrent worker threads sharing one in-memory connection is inherent
to the *intended* sharing design (pre-fix the workers used separate, wrong connections), not
introduced by the fix; general concurrency is outside the bundled K tier. Stated as an open
obligation and routed to the concurrency sources — **never faked as `[trusted]`**. → **no
change.**

### Decision 8 — confirm import safety / no `runserver` regression (F7/PO7)
Traces to **PO7** and **F7**. Static check: `django/db/__init__.py` imports nothing that pulls
in `basehttp`, so the new `from django.db import connections` is acyclic; `runserver` builds
its threaded server with `type(...)` in `basehttp.run()` and never touches `ThreadedWSGIServer`,
so it is unaffected. → confirms the fix's scope; **no change.**

## Honesty / status

The proof is **constructed, not machine-checked** (the MVP does not run `kompile`/`kprove`);
the emitted commands are in [`fvk/PROOF.md`](../fvk/PROOF.md) §8 and [`fvk/SPEC.md`](../fvk/SPEC.md)
§6. The benefit-2 findings (F1–F8) do not depend on machine-checking and are reported with
full confidence; no test removals are recommended (and this audit may not edit tests anyway).
