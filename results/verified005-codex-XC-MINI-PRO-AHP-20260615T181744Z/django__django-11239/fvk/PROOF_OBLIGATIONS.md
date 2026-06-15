# PROOF OBLIGATIONS

Status legend: discharged by source inspection, constructed not machine-checked.

## PO-001: Source of SSL inputs

- Obligation: PostgreSQL `OPTIONS` keys are available to `runshell_db()` through
  `conn_params`.
- Evidence: `get_connection_params()` creates `{'database': NAME, **OPTIONS}`.
- Status: discharged.

## PO-002: Argument frame

- Obligation: adding SSL support must not change the existing `psql` argument
  list construction.
- Expected form:
  `['psql'] + optional ['-U', user] + optional ['-h', host] + optional ['-p', str(port)] + [database]`
- Evidence: V1 changes only environment construction after args are built.
- Status: discharged.

## PO-003: Password environment frame

- Obligation: when `password` is truthy, `PGPASSWORD` is set to `str(password)`;
  otherwise existing behavior is preserved.
- Evidence: V1 leaves the original password block intact.
- Status: discharged.

## PO-004: SSL environment mapping

- Obligation: when each SSL connection parameter is truthy, the subprocess
  environment contains the corresponding libpq environment variable:
  - `sslmode -> PGSSLMODE`
  - `sslrootcert -> PGSSLROOTCERT`
  - `sslcert -> PGSSLCERT`
  - `sslkey -> PGSSLKEY`
- Evidence: `ssl_env` dictionary and loop in V1 source.
- Status: discharged.

## PO-005: Environment frame for unrelated variables

- Obligation: unrelated environment entries remain those of `os.environ.copy()`.
- Evidence: V1 starts from `os.environ.copy()` and updates only `PGPASSWORD` and
  the issue-named SSL variables.
- Status: discharged.

## PO-006: SIGINT restoration

- Obligation: the original SIGINT handler is restored even if `subprocess.run`
  raises.
- Evidence: V1 does not change the existing `try` / `finally` structure.
- Status: discharged.

## PO-007: Public compatibility

- Obligation: no public method signature, caller protocol, or visible argument
  order changes.
- Evidence: compatibility audit in `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
- Status: discharged.

## PO-008: Machine-check and runtime validation

- Obligation: the constructed K proof and runtime behavior should be checked in
  an execution-capable environment.
- Evidence: emitted commands in `fvk/PROOF.md`; benchmark forbids executing them
  here.
- Status: open outside this session, not a code defect.
