# Proof Obligations

Status: constructed, not machine-checked.

## PO-01: Parameters precede configured dbname

Statement: If `settings_dict["NAME"]` resolves to a PostgreSQL database name,
then returned `args` must have `parameters` before that database name, and the
database name must be the final positional argument.

Formal claim: C-DBNAME in `fvk/postgresql-dbshell-spec.k`.

Evidence: IE-01, IE-02, IE-04.

V1 result: discharged by source inspection and constructed K claim.

## PO-02: Parameters precede default `postgres` dbname

Statement: If neither `NAME` nor service is configured, Django's synthesized
`postgres` database is still a positional database argument and must come after
`parameters`.

Formal claim: C-DEFAULT-POSTGRES in `fvk/postgresql-dbshell-spec.k`.

Evidence: IE-02, IE-04 and the source branch that sets `dbname = "postgres"`.

V1 result: discharged by source inspection and constructed K claim.

## PO-03: Service-only configuration has no positional dbname

Statement: If service is configured and `NAME` is absent, V1 must not add a
positional database name while reordering parameters.

Formal claim: C-SERVICE-NO-DBNAME in `fvk/postgresql-dbshell-spec.k`.

Evidence: IE-09.

V1 result: discharged by source inspection and constructed K claim.

## PO-04: Environment construction is preserved

Statement: `PGPASSWORD`, `PGSERVICE`, `PGSSLMODE`, `PGSSLROOTCERT`,
`PGSSLCERT`, `PGSSLKEY`, and `PGPASSFILE` are populated under the same
conditions as before V1.

Formal status: frame obligation outside the K list-order model.

Evidence: IE-08.

V1 result: discharged by source inspection; V1 moves only `args.extend(parameters)`.

## PO-05: Existing connection option prefix is preserved

Statement: User, host, and port options continue to appear before both
`parameters` and any positional database argument.

Formal claims: all three claims in `fvk/postgresql-dbshell-spec.k` include
`userOpt`, `hostOpt`, and `portOpt` before `PARAMS`.

Evidence: IE-05 and current PostgreSQL client source.

V1 result: discharged by source inspection and constructed K claim.

## PO-06: Management command and base client pass through returned args

Statement: `dbshell` still passes the parsed `parameters` list to the selected
backend client, and `BaseDatabaseClient.runshell()` still executes the returned
`args` list.

Formal status: compatibility/frame obligation by source inspection.

Evidence: IE-05, IE-06.

V1 result: discharged; no code in these files changed.

## PO-07: Public API and backend compatibility are preserved

Statement: V1 must not change public method signatures, return shapes, or other
backend command construction.

Formal status: compatibility obligation.

Evidence: `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

V1 result: discharged; only PostgreSQL internal list ordering changed.
