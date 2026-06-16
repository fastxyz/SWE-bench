# FVK Findings

Status: constructed, not machine-checked. No tests, Python code, or K tooling were run.

## F1: Pre-fix request worker DB connections are not explicitly closed

Classification: code bug, fixed by V1 and retained by V2.

Evidence: E1, E2, E3; proof obligations PO-1 and PO-2.

Input -> observed vs expected:

- Input: a `LiveServerTestCase` request handled by a `ThreadedWSGIServer` worker thread, where that request opens one or more Django DB connections.
- Observed before the fix: `ThreadedWSGIServer` inherited `TCPServer.close_request()` and only closed the request/socket; it did not call `connections.close_all()` in the request worker thread.
- Expected: when the request worker reaches `close_request()`, all Django DB connections visible in that worker thread are closed before request cleanup completes.

Resolution: `ThreadedWSGIServer.close_request()` now calls `connections.close_all()` from the request worker thread.

## F2: V1 could skip inherited request cleanup if DB cleanup raised

Classification: code bug in the V1 patch, fixed by V2.

Evidence: E4; proof obligations PO-3 and PO-4.

Input -> observed vs expected:

- Input: V1 `ThreadedWSGIServer.close_request(request)` with `connections.close_all()` raising an exception.
- Observed in V1: `super().close_request(request)` was sequenced after `connections.close_all()` without `finally`, so inherited request/socket cleanup was not guaranteed on that path.
- Expected: adding DB cleanup must not remove the existing `TCPServer.close_request()` cleanup guarantee; `super().close_request(request)` should run even if the added cleanup raises.

Resolution: V2 wraps `connections.close_all()` in `try/finally` and calls `super().close_request(request)` in the `finally` block.

## F3: SQLite in-memory thread-sharing remains a separate scope boundary

Classification: underspecified/separate issue, no V2 source change.

Evidence: E8; proof obligation PO-6.

Input -> observed vs expected:

- Input: `LiveServerTestCase` using SQLite in-memory databases and threaded request workers.
- Observed from public issue notes: the reporter says this may also be a problem and then identifies it as previously reported separately.
- Expected for this task: fix the accepted DB-connection leak after request threads. Do not claim the close-request proof also proves SQLite connection sharing across worker threads.

Resolution: no code change in V2 for SQLite sharing. The FVK proof and report explicitly exclude that concern from the proven contract.

## F4: Proof is constructed only, not machine-checked

Classification: proof capability gap, not a code bug.

Evidence: FVK command instructions; proof obligation PO-7.

Input -> observed vs expected:

- Input: the generated K semantics and claims under `fvk/`.
- Observed in this environment: K tooling must not be run.
- Expected: record exact `kompile`, `kast`, and `kprove` commands and label the proof "constructed, not machine-checked."

Resolution: commands are recorded in `fvk/SPEC.md` and `fvk/PROOF.md`; no test deletion or machine-checked claim is made.
