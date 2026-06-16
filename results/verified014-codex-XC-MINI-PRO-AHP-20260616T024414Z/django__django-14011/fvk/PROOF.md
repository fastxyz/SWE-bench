# FVK Proof

Status: constructed, not machine-checked. No tests, Python code, or K tooling were run.

## Claims

Formal claims are in `fvk/threaded-wsgi-server-spec.k`.

C1 proves the normal path:

- Precondition: `N >= 0` current-thread DB connections are open; `closeAllOutcome = normal`; request cleanup has not run.
- Postcondition: `dbOpen = 0`; `requestClosed = true`; no exception is recorded.

C2 proves the DB-cleanup exceptional path:

- Precondition: `N >= 0` current-thread DB connections are open; `closeAllOutcome = dbError`; request cleanup has not run.
- Postcondition: `requestClosed = true`; the DB exception is recorded and propagated. The remaining DB-open count is existential because a failing `close_all()` cannot prove all DB resources closed.

## Constructed Proof Sketch

### C1: normal cleanup

1. Start with `<k> close_request </k>`, `dbOpen = N`, `requestClosed = false`, and `closeAllOutcome = normal`.
2. Apply the `close_request` rule. The computation becomes `try_close_all_finally_super`.
3. Apply the normal `try_close_all_finally_super` rule. The computation becomes `close_all ~> super_close_request`.
4. Apply the normal `close_all` rule. This rewrites `dbOpen` from `N` to `0`.
5. Apply `super_close_request`. This rewrites `requestClosed` from `false` to `true`.
6. The computation reaches `.K`, satisfying C1.

Mapping to Django:

- Step 4 corresponds to `connections.close_all()` in the request worker thread.
- Step 5 corresponds to `super().close_request(request)`.

Discharged obligations: PO-1, PO-2, PO-3, PO-5.

### C2: DB cleanup raises

1. Start with `<k> close_request </k>`, `dbOpen = N`, `requestClosed = false`, and `closeAllOutcome = dbError`.
2. Apply the `close_request` rule. The computation becomes `try_close_all_finally_super`.
3. Apply the exceptional `try_close_all_finally_super` rule. The computation becomes `close_all ~> super_close_request ~> raise_db_error`.
4. Apply the exceptional `close_all` rule. This records `exception = true` and leaves the DB-open count unconstrained.
5. Apply `super_close_request`. This rewrites `requestClosed` from `false` to `true`.
6. Apply `raise_db_error`. The computation reaches `.K` with `exception = true`, satisfying C2's abstract exceptional outcome.

Mapping to Django:

- Steps 3 to 5 correspond to the V2 `try/finally` structure.
- The proof does not claim DB connections are closed if `connections.close_all()` itself fails.

Discharged obligations: PO-3 and PO-4.

## Adequacy Check

The formal observable distinguishes the relevant failing and passing cases:

- Failing pre-fix instance: `dbOpen = 1`, normal inherited `close_request()` only. The model would leave `dbOpen = 1`, violating C1.
- Passing V2 instance: `dbOpen = 1`, V2 `close_request()`. The model reaches `dbOpen = 0` and `requestClosed = true`.
- Failing V1 exceptional instance: `closeAllOutcome = dbError` with no `finally`. The model would not force `requestClosed = true`, violating C2.
- Passing V2 exceptional instance: `closeAllOutcome = dbError` with `finally`. The model reaches `requestClosed = true`.

This means the abstraction preserves the two properties under audit: request-thread DB cleanup and inherited request cleanup.

## Machine Check Commands

These commands are the exact intended commands for later machine checking. They were not run.

```sh
cd fvk
kompile mini-close-request.k --backend haskell
kast --backend haskell threaded-wsgi-server-spec.k
kprove threaded-wsgi-server-spec.k
```

Expected machine-check result after the commands are run in an environment with K installed: `kprove` returns `#Top` for C1 and C2. This expectation is constructed from the proof above, not observed.

## Test Guidance

No tests were run and no tests were modified.

Conditionally redundant after successful machine checking:

- A narrow unit test that only asserts `ThreadedWSGIServer.close_request()` calls `connections.close_all()` on the normal path would be subsumed by C1.

Keep:

- Live-server integration tests, including threaded nested-request behavior. The formal model is an abstract cleanup proof, not an end-to-end proof of HTTP serving or thread scheduling.
- Any SQLite in-memory thread-sharing tests. That concern is outside C1/C2.
- Any exceptional-path test asserting superclass request cleanup still occurs if DB cleanup raises, unless C2 is machine-checked and the test is intentionally classified as redundant later.

## Residual Risk

The proof is partial and abstract. It proves cleanup properties for the modeled `close_request()` paths, not total correctness of the live server, thread termination, socketserver internals, or database backend close implementations.

The trusted base is the adequacy of `mini-close-request.k`, the public issue's description of `ThreadingMixIn` cleanup order, Django's thread-local `connections` behavior, and a future K machine check. Until `kprove` is actually run, this remains constructed rather than machine-verified.
