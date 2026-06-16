# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python code, or K tooling were run.

## V2 Decision

V2 should stand with one improvement over V1:

- Keep the V1 behavior that calls `connections.close_all()` from `ThreadedWSGIServer.close_request()`.
- Add `try/finally` so `super().close_request(request)` runs even if DB cleanup raises.

This resolves F1 and F2 and discharges PO-1 through PO-5 for the cleanup behavior in scope.

## Do Not Change for This Issue

Do not replace `ThreadedWSGIServer` with `WSGIServer`.

Reason: threaded behavior is public behavior for `LiveServerTestCase`; public tests state that non-threaded live-server behavior can hang nested request scenarios. See E7 and PO-5.

Do not implement SQLite in-memory worker-thread sharing in this patch.

Reason: the issue notes identify it as related and previously reported separately. The FVK proof does not cover it. See F3 and PO-6.

Do not edit tests.

Reason: the benchmark fixes production code only, and the proof is not machine-checked. See F4 and PO-7.

## Suggested Follow-up Tests for a Normal Development Environment

These are recommendations only; they were not added here.

1. A unit or integration test where a live-server request opens a DB connection in a request worker thread, then verifies that the worker's connection is closed after request cleanup.
2. A focused test using a fake `connections.close_all()` that raises, verifying that `super().close_request(request)` still closes the request.
3. Existing threaded live-server nested-request tests should continue to run to preserve compatibility.

## Suggested Machine Check

Run only in an environment with K installed and where execution is allowed:

```sh
cd fvk
kompile mini-close-request.k --backend haskell
kast --backend haskell threaded-wsgi-server-spec.k
kprove threaded-wsgi-server-spec.k
```

Expected result from the constructed proof: `kprove` discharges C1 and C2 to `#Top`.

## Next Prompt for a Code Generator

If another repair pass is needed, use this prompt:

"Keep the `ThreadedWSGIServer.close_request()` override. Ensure `connections.close_all()` runs in the request worker thread and that `super().close_request(request)` runs in a `finally` block. Do not change `LiveServerThread.server_class`, do not remove threaded behavior, and do not address SQLite in-memory thread sharing in this patch."
