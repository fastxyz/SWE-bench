# FVK Notes

Status: constructed, not machine-checked. No tests, Python code, or K tooling were run.

## Decisions

D1. Kept the V1 decision to add database cleanup to `ThreadedWSGIServer.close_request()`.

Trace: `fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` PO-1/PO-2. The public issue identifies request worker threads as the leaking lifecycle, and `close_request()` is the cleanup hook reached in that same worker thread.

D2. Revised V1 to call `super().close_request(request)` in a `finally` block.

Trace: `fvk/FINDINGS.md` F2 and `fvk/PROOF_OBLIGATIONS.md` PO-3/PO-4. V1 closed DB connections before superclass cleanup, but if `connections.close_all()` raised, inherited request/socket cleanup was not guaranteed. V2 preserves that cleanup unconditionally.

D3. Did not replace `ThreadedWSGIServer` with non-threaded `WSGIServer`.

Trace: `fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` PO-5. The issue mentions non-threaded serving only as a reproduction workaround, while public live-server tests document that threaded behavior is required for nested request scenarios.

D4. Did not implement SQLite in-memory thread-sharing changes.

Trace: `fvk/FINDINGS.md` F3 and `fvk/PROOF_OBLIGATIONS.md` PO-6. The issue notes call that concern related and separately reported. The proven contract for this patch is request-thread DB cleanup, not SQLite connection sharing.

D5. Did not modify tests and did not claim machine-checked proof.

Trace: `fvk/FINDINGS.md` F4 and `fvk/PROOF_OBLIGATIONS.md` PO-7. The task forbids test edits and execution. The FVK artifacts record the commands needed for later `kompile`, `kast`, and `kprove` checks but do not report them as run.

## Files Changed

`repo/django/core/servers/basehttp.py`

- Imports `connections`.
- Adds `ThreadedWSGIServer.close_request()`.
- Calls `connections.close_all()` in the request worker thread.
- Calls `super().close_request(request)` from `finally` to preserve inherited cleanup even if DB cleanup raises.

`fvk/`

- Adds the five requested FVK artifacts.
- Adds `mini-close-request.k` and `threaded-wsgi-server-spec.k` as the formal core required by the FVK documentation.

`reports/fvk_notes.md`

- Records this decision trace.

## Result

V2 is a minimal improvement over V1. It keeps the original leak fix and strengthens compatibility with the inherited `close_request()` cleanup contract.
