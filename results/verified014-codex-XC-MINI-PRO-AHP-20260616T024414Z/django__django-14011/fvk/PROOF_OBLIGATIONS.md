# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python code, or K tooling were run.

## PO-1: Request-thread cleanup hook

Claim: Every `ThreadedWSGIServer` request worker reaches `ThreadedWSGIServer.close_request(request)` through the `ThreadingMixIn.process_request_thread()` cleanup path described in the public issue.

Required discharge: The fix must put DB cleanup in `ThreadedWSGIServer.close_request()`, not only in `LiveServerThread.run()`, `terminate()`, or test teardown.

Evidence: E1, E2, E3.

Finding link: F1.

Status: discharged by V2. `ThreadedWSGIServer` now overrides `close_request()`.

## PO-2: Same-thread database closure

Claim: On the normal path where `connections.close_all()` returns, each current-thread Django DB connection visible through `connections` is closed.

Required discharge: `connections.close_all()` must execute inside the request worker thread, because Django connections are stored in thread-local connection storage.

Evidence: E2, E5, E6.

Finding link: F1.

Status: discharged by V2 on the normal path. The K claim C1 models `dbOpen = N` becoming `dbOpen = 0`.

## PO-3: Preserve inherited request cleanup

Claim: The override must still perform the superclass `close_request()` behavior that closes the individual request/socket.

Required discharge: `super().close_request(request)` must be called by the override with the original request argument.

Evidence: E4.

Finding link: F2.

Status: discharged by V2. `super().close_request(request)` remains in the override.

## PO-4: Preserve inherited cleanup on DB-close exception

Claim: Adding DB cleanup must not make inherited request cleanup conditional on `connections.close_all()` succeeding.

Required discharge: `super().close_request(request)` must run in a `finally` block or equivalent cleanup path.

Evidence: E4 and F2.

Finding link: F2.

Status: discharged by V2. The override uses `try: connections.close_all() finally: super().close_request(request)`.

## PO-5: Public compatibility

Claim: The fix must not remove threaded live-server behavior or break public subclass/callsite compatibility.

Required discharge:

- Do not replace `ThreadedWSGIServer` with `WSGIServer`.
- Do not change the `close_request(self, request)` signature.
- Do not change `LiveServerThread.server_class` customization.

Evidence: E7 and public compatibility audit in `fvk/SPEC.md`.

Finding link: F1.

Status: discharged by V2. The patch only adds an override with the inherited signature and leaves threading behavior unchanged.

## PO-6: SQLite sharing scope boundary

Claim: This proof must not overclaim that closing request-thread DB connections also fixes SQLite in-memory thread-sharing behavior.

Required discharge: State the boundary explicitly and avoid unrelated SQLite connection-sharing edits.

Evidence: E8.

Finding link: F3.

Status: discharged. V2 does not edit SQLite/thread-sharing logic and the spec excludes it from the proven contract.

## PO-7: Honesty gate for machine checking

Claim: FVK artifacts must not claim machine-checked verification because this environment forbids running K tooling.

Required discharge: Include exact commands for later checking and label the proof constructed, not machine-checked.

Evidence: FVK `verify.md` honesty gate.

Finding link: F4.

Status: discharged in `fvk/SPEC.md` and `fvk/PROOF.md`.
