# FVK Notes

Status: constructed, not machine-checked. I did not run tests, Python, or K
tooling.

## Decisions

D1. Kept V1 source unchanged.

Trace: F-1 shows the password case now uses `subprocess.run()` with
`PGPASSWORD` in the subprocess environment while preserving argv construction.
PO-1, PO-2, and PO-3 discharge those obligations.

D2. Did not reintroduce `.pgpass`, `NamedTemporaryFile`, `_escape_pgpass()`, or
`PGPASSFILE`.

Trace: F-2 identifies the existing `.pgpass` public tests as SUSPECT legacy
evidence because they contradict the issue's explicit replacement request.
PO-2 proves the new environment behavior and PO-6 explains why the legacy test
expectation is not binding.

D3. Kept SIGINT handling as V1 left it.

Trace: F-3 confirms the original `try/finally` signal restoration shape is
still present. PO-4 discharges restoration on both normal and exceptional
subprocess paths.

D4. Made no public API or callsite changes.

Trace: F-4 confirms `runshell_db(cls, conn_params)`, `runshell(self)`, and the
management command dispatch remain compatible. PO-5 discharges the public
compatibility obligation.

D5. Did not add password type coercion.

Trace: F-5 records string-like password values as the audited domain, supported
by `get_connection_params()` and the public tests. PO-8 accepts that
precondition. A broader hardening change would exceed the public issue.

D6. Did not claim proof over external `psql` behavior.

Trace: F-6 and PO-7 classify external PostgreSQL client interpretation of
`PGPASSWORD` as a proof boundary. The source-level obligation is to pass the
environment variable to the child process, which PO-2 discharges.

## Artifacts Produced

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-python-dbshell.k`
- `fvk/postgresql-client-spec.k`

## Result

The FVK audit found no justified source edit beyond V1. V1 stands unchanged.
