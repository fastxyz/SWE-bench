# ITERATION GUIDANCE

## Decision

V1 stands unchanged. The FVK audit found the original missing TLS forwarding
bug and confirmed that V1 discharges the issue-derived obligations without a
broader or riskier source edit.

## Why no V2 source edit is needed

- F-001 is resolved by PO-004: the current source maps each issue-named SSL
  parameter to the corresponding libpq environment variable.
- F-002 confirms the frame obligations: existing args, password behavior,
  subprocess call shape, and SIGINT restoration are unchanged.
- F-003 rejects broader arbitrary libpq forwarding as under-specified by the
  issue and unnecessary for mutual TLS support.

## Recommended tests for a runnable environment

Do not edit tests in this benchmark. In a normal development environment, add a
PostgreSQL dbshell test that mocks `subprocess.run()` and verifies:

- `sslmode` sets `PGSSLMODE`
- `sslrootcert` sets `PGSSLROOTCERT`
- `sslcert` sets `PGSSLCERT`
- `sslkey` sets `PGSSLKEY`
- existing args and `PGPASSWORD` behavior are unchanged

## Machine-check guidance

The K artifacts are constructed, not machine-checked. A future FVK iteration
with K available should run the commands in `fvk/PROOF.md`, resolve any
toolchain feedback, and require `kprove` to return `#Top` before claiming
machine-checked proof.
