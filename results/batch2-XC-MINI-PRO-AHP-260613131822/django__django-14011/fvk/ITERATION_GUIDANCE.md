# ITERATION GUIDANCE — V1 fix for django__django-14011

Feedback package for the next generate→formalize→verify pass. Per the FVK loop, this
records the questions an intent-elicitation (UltimatePowers) layer should ask and the
concrete code/spec/test follow-ups — it does **not** silently regenerate code. The
audit's bottom line is **V1 stands**; the items below are documentation/robustness
follow-ups, not corrections.

---

## Outcome

All proof obligations PO1–PO7 are **discharged** (constructed); PO8 is a stated
**escalation boundary**. No finding is a correctness defect. **No source change is
required**; V1 is confirmed. The findings that drove "keep V1" decisions are F4, F6,
F8 (accepted trade-offs) and F5 (residual concurrency boundary).

## UltimatePowers questions (intent the next pass should pin down)

- **Q1 (from F2 / PROOF §6).** *What is the contract on `connections_override`?* The
  proof relies on `allShared(OV)` — every overridden connection must be thread-shared
  (`inc_thread_sharing()`). Should this be (a) documented as a caller contract,
  (b) defensively asserted in `ThreadedWSGIServer`, or (c) left implicit because the only
  in-tree caller (`LiveServerTestCase.setUpClass`) already guarantees it? *Recommended
  answer: (a) — document; (c) in practice. Do not add a runtime assert (noise on a hot
  path, and `setUpClass` is the sole producer).*

- **Q2 (from F5 / PO8).** *What concurrency guarantee does `LiveServerTestCase` promise
  for in-memory SQLite?* Sequential requests only, or concurrent? This bounds whether the
  shared-connection race is even reachable. *Recommended answer: document "in-memory
  SQLite shares one connection; concurrent requests are not guaranteed race-free" — the
  pre-existing reality, now made explicit.*

- **Q3 (from F4).** *Is changing the private `_create_server` signature acceptable for the
  release?* *Recommended answer: yes — note in release notes that `LiveServerThread.server_class`
  (not a `_create_server` override) is the supported customization point, and that a custom
  `server_class` must accept a `connections_override` keyword.*

## Recommended next code/spec changes (all LOW priority; none block)

1. **Docs only (Q1/Q2/Q3).** A sentence in the `LiveServerTestCase` docs / release notes
   capturing the `connections_override` thread-sharing contract and the `server_class`
   keyword contract. *No behavioral code change.*
2. **Optional clarity (F8).** A one-line comment in `LiveServerThread.run()` noting that the
   server thread's override copy is vestigial and that per-request sharing now lives in
   `ThreadedWSGIServer.process_request_thread`. *Deferred — not applied, to keep the diff
   minimal and avoid churn; the rationale is recorded in FINDINGS F8.*
3. **Do NOT** add a `try/finally` around `_close_connections()` in `close_request` (F6):
   it would diverge from the issue's prescribed snippet for a negligible, rare-path gain.

## Tests to add / keep (machine-check first; this audit cannot edit tests)

- **Add (if not already in the hidden suite):**
  - `ThreadedWSGIServer` closes connections after a request — assert (e.g. via mocking
    `_close_connections`) it is invoked once per finished request, with and without a
    `Content-Length` (persistent vs `Connection: close`) response.
  - in-memory-SQLite `LiveServerTestCase`: the live view reads a row the test created
    (locks in C2-share / F3, the #29062 regression).
- **Keep (outside the verified domain — see PROOF §5):** concurrency/load, termination of
  `serve_forever`/`terminate`, Selenium-style integration, and any custom
  `server_class`/`_create_server` tests (F4 contract).
- **Remove:** none (proof is constructed, not machine-checked — Honesty gate).

## Escalation pointers

- **PO8 / F5 concurrency:** route to the reachability sources (one-path vs all-path,
  LICS 2013) and a true-concurrency K model — beyond the bundled tier. A worked
  concurrent example is the right growth lever before attempting a machine-checked
  multi-thread contract.
