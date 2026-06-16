# FVK Findings

Status: constructed, not machine-checked.

## F-01: Legacy PostgreSQL parameter ordering bug is resolved by V1

Classification: code bug, resolved.

Input: `settings_dict={"NAME": "dbname"}`,
`parameters=["-c", "select * from some_table;"]`.

Observed before V1: `["psql", "dbname", "-c", "select * from some_table;"]`.
The issue reports that `psql` treats `-c` and the SQL string as extra arguments
and ignores them after a positional database name.

Expected: `["psql", "-c", "select * from some_table;", "dbname"]`.

V1 status: resolved. Current source appends `parameters` before appending
`dbname`.

Trace: IE-01, IE-03, IE-04; PO-01.

## F-02: Public PostgreSQL `test_parameters` expectation is SUSPECT

Classification: stale public test evidence, not a code bug in V1.

Input: `settings_dict={"NAME": "dbname"}`, `parameters=["--help"]`.

Observed public test expectation:
`["psql", "dbname", "--help"]`.

Expected from public issue intent:
`["psql", "--help", "dbname"]`.

Reason: the issue explicitly says additional parameters should be before dbname
and the database name should be left at the end. The public test expectation
therefore encodes the legacy behavior the issue rejects and must not be used as
an oracle for V1.

Trace: IE-01, IE-04, IE-07; PO-01.

## F-03: Default `postgres` positional database follows the same ordering rule

Classification: proof-derived confirmation.

Input: no `NAME`, no service, `parameters=["-c", "select 1"]`.

Expected: Django's default positional database `"postgres"` comes after
`parameters`: `["psql", "-c", "select 1", "postgres"]`, plus any configured
user/host/port prefix.

V1 status: confirmed. Current source sets `dbname = "postgres"` before argument
assembly and then appends `parameters` before appending `dbname`.

Trace: IE-02, IE-04; PO-02.

## F-04: Service-only configurations remain unchanged

Classification: proof-derived frame confirmation.

Input: service configured, no `NAME`, any `parameters`.

Expected: no positional database name is appended; the service is supplied via
`PGSERVICE`.

V1 status: confirmed. Moving `args.extend(parameters)` before the dbname append
does not create a dbname when `dbname` is false.

Trace: IE-08, IE-09; PO-03, PO-04.

## F-05: No additional production-code change is justified

Classification: audit conclusion.

The proof obligations cover the intended ordering behavior for all relevant
PostgreSQL dbname branches and the frame obligations cover unchanged env and API
behavior. No unresolved code bug or compatibility gap was found.

Trace: PO-01 through PO-07.

## Residual Caveat

The proof is constructed, not machine-checked. The emitted K commands in
`fvk/PROOF.md` were not run in this environment.
