# SPEC — `ThreadedWSGIServer` per-request connection lifecycle (V1 fix audit)

Formal specification produced by applying `/formalize` (fvk_materials) to the V1
fix for django__django-14011. **Intent-spec mode**: the contract is derived from the
issue intent (`benchmark/PROBLEM.md`) and the code is checked against it.

Artifacts: [`mini-server.k`](mini-server.k) (mini-X semantics),
[`mini-server-spec.k`](mini-server-spec.k) (the `(CLOSEALL)` + `(PRT)` claims). This
note is the plain-English version for a developer who never opens the `.k` files.

---

## 1. Component and intent

**Code under spec** (V1 fix):

- `django/core/servers/basehttp.py` — `ThreadedWSGIServer.__init__`,
  `.process_request_thread`, `._close_connections`, `.close_request`.
- `django/test/testcases.py` — `LiveServerThread.run`, `._create_server`.

**Intent (from the issue).** `LiveServerTestCase` runs a live HTTP server in a
thread; `ThreadedWSGIServer` (= `socketserver.ThreadingMixIn` + `WSGIServer`) spawns
a **new worker thread per request**. Two defects:

1. Worker threads never closed the DB connections they opened ⇒ connections leaked
   ⇒ `destroy_test_db()` raced with `OperationalError: database "test_…" is being
   accessed by other users` (a regression of #22414).
2. Worker threads did not apply the in-memory-SQLite thread-sharing that
   `LiveServerThread.run()` applies only in its *own* thread ⇒ a worker would create
   a *fresh, empty* in-memory DB instead of the test's shared one (#29062).

## 2. The intended contract (plain language)

Let a **worker thread** be one invocation of `process_request_thread`. Let
`connections_override` (`OV`) be the set of shared in-memory connections handed in by
the test (each already `inc_thread_sharing()`'d, hence **openShared**: open, and whose
`close()` is a no-op).

- **C1 — no connection leak.** Every DB connection a worker thread opens while
  serving its request is **closed** before that worker thread terminates. ⇒ once all
  requests are done and the server thread stops, **no worker-thread connection is left
  open**, so `destroy_test_db()` succeeds.
- **C2 — in-memory sharing.**
  - *(share)* A worker thread serving a request uses **the same** `OV` connection
    objects the test owns (so the view sees the test's data), **not** fresh ones.
  - *(preserve)* The per-request cleanup must **not** destroy an `OV` connection (it
    is owned by the test thread and its in-memory DB must survive across requests).
- **C3 — no regression for non-shared DBs.** For a non-shared DB (postgres / mysql /
  file SQLite), each worker thread's own connection is **really closed** after its
  request.
- **C4 — graceful with no override.** If `connections_override` is `None`/empty, the
  server still closes per-request connections (C1) and applies no override.

## 3. Preconditions (assumptions the contract relies on)

| # | Precondition | Where it holds |
|---|---|---|
| P1 | `finish_request` and `close_request` run in the **same** worker thread. | CPython `ThreadingMixIn.process_request_thread`: `try: finish_request … finally: shutdown_request → close_request`. |
| P2 | In-memory SQLite `close()` is a **no-op** (preserves the DB). | `django/db/backends/sqlite3/base.py:270` (`if not self.is_in_memory_db(): super().close()`). |
| P3 | Shared conns are `inc_thread_sharing()`'d, so `validate_thread_sharing()` passes when a worker thread closes them. | `LiveServerTestCase.setUpClass`; decremented only in `_tearDownClassInternal`. |
| P4 | `connections` storage is **thread-local** — each worker thread has its own view; `close_all()` only touches the calling thread's connections. | `django/utils/connection.py` (`Local`, `__setitem__`/`__getitem__`). |
| P5 | `from django.db import connections` in `basehttp.py` introduces **no import cycle**. | `django/db/__init__.py` imports only `core.signals`, `db.utils`, `utils.connection`; none import `basehttp`. |
| P6 | The `request_finished` signal's `close_old_connections` cannot destroy a shared conn. | It calls `self.close()`, a no-op for in-memory (P2). |

## 4. The mini-X semantics ([`mini-server.k`](mini-server.k))

We model **one worker thread** as a small-step program over a thread-local
connection list `<own>`, an immutable `<override>` (`OV`), and an `<accesses>` counter
`N` (distinct non-shared DBs the request touches). A connection is `openShared`
(in-memory, shared — `close` is a no-op), `openLocal` (a non-shared conn this thread
opened — `close` really closes), or `closed`.

| construct | models | rule effect |
|---|---|---|
| `setOverride` | `if self.connections_override: connections[alias]=conn` | append `OV` to `<own>` |
| `handleRequest` | `finish_request` lazily opening non-shared conns | append `mkLocals(N)` (N × `openLocal`) to `<own>` |
| `closeAll` | `_close_connections()` → `connections.close_all()` | drain `<own>` head-first into `<closed>`, applying `close()` |
| `close(·)` | `DatabaseWrapper.close()` | `openShared↦openShared`, `openLocal↦closed`, `closed↦closed` |

The worker-thread lifecycle is exactly `setOverride ; handleRequest ; closeAll`.

## 5. The claims ([`mini-server-spec.k`](mini-server-spec.k))

**`(CLOSEALL)` — loop circularity** for `connections.close_all()`, generalized over
the processed accumulator `D` and the remaining list `L`:

> from `⟨closeAll⟩ <own>=L <closed>=D` reach `⟨.K⟩ <own>=.List <closed>=D closeList(L)`

where `closeList = map(close, ·)`. No counter bound is needed — `|own|` strictly
decreases, so the same measure also gives **termination** (total correctness here, not
just partial). This is the loop invariant, in the count-down/"remaining-work" shape.

**`(PRT)` — `process_request_thread` contract**, composing the three statements:

> **pre:** `<own>=.List` (fresh thread) ∧ `allShared(OV)` ∧ `N ≥ 0`
> **post:** `<own>=.List` ∧ `<closed> = closeList(OV) mkClosed(N)`

i.e. after a worker thread runs, its final connection multiset is *every shared conn
preserved* (`closeList(OV)=OV` since each is `openShared`) *plus every non-shared conn
closed* (`mkClosed(N)`).

**Corollary (the contract that fixes the bug):** `closeList(OV) mkClosed(N)` contains
**no `openLocal`** ⇒ no thread-local DB connection leaks past a request (**C1/C3**),
and contains **every `openShared` of `OV` unchanged** ⇒ the in-memory DB survives
(**C2-preserve**). **C2-share** is the *program-order* fact that `setOverride`
precedes `handleRequest`, so the shared conn is in `<own>` before the request reads it
(proved by Transitivity in [`PROOF.md`](PROOF.md), not needing the loop). **C4** is the
`N=0`, `OV=.List` instance: post `= .List`.

## 6. Run-commands (constructed, **not machine-checked**)

```sh
kompile mini-server.k --backend haskell        # compile the fragment semantics
kast    --backend haskell mini-server-spec.k    # (optional) parse-check the claims
kprove  mini-server-spec.k                       # discharge (CLOSEALL) and (PRT); expect #Top
```

Per the FVK Honesty gate: these are **emitted, not run**. A `#Top` from `kprove` is
what would upgrade this from *constructed* to *machine-verified*.

## 7. Spec-difficulty signals (feed the Findings)

Writing this spec cleanly required (a) restricting to **one** worker thread — the
multi-thread interleaving has no clean single-trace contract and is flagged as an
**escalation boundary** (FINDINGS F5); (b) the precondition `allShared(OV)` (P3) —
the contract is *false* if an override conn is not thread-shared, because then a
worker's `close()` would raise `validate_thread_sharing` (FINDINGS F2/F-pre). Both
difficulties are real signals, recorded as findings rather than papered over.
