# FVK Spec

Status: constructed, not machine-checked.

## Scope

Target: `repo/django/db/backends/postgresql/client.py`,
`DatabaseClient.settings_to_cmd_args_env()`.

Observable under audit: the `(args, env)` pair returned for PostgreSQL
`dbshell`. The formal model focuses on the argument list because the reported
bug is an order-sensitive `psql` parsing failure. Environment construction is
tracked as a frame obligation because V1 does not alter it.

## Public Intent Ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The controlling entries
are:

- IE-01 and IE-04: additional PostgreSQL `dbshell` parameters must precede the
  positional dbname, leaving dbname at the end of the args list.
- IE-03: legacy ordering causes `psql` to ignore `-c` and its SQL argument as
  extra command-line arguments.
- IE-07: the existing public `test_parameters` expectation is SUSPECT because
  it encodes the legacy order that the issue contradicts.

## Contract

For any PostgreSQL settings handled by this client:

1. Start `args` with `["psql"]`.
2. Preserve the existing configured connection option prefix: `-U user`,
   `-h host`, and `-p port`, each only when configured.
3. Append the `parameters` list collected by `manage.py dbshell -- ...` before
   any positional database name.
4. If `NAME` is present, append `NAME` after `parameters`.
5. If `NAME` is absent and service is absent, append the default `"postgres"`
   after `parameters`.
6. If service is present and `NAME` is absent, append no positional database
   name.
7. Preserve environment variable construction for password, service, passfile,
   and SSL settings.

## Formal Core

The constructed K artifacts are:

- `fvk/mini-postgresql-dbshell.k`: a domain-specific mini semantics for the
  PostgreSQL `dbshell` argument builder.
- `fvk/postgresql-dbshell-spec.k`: three reachability claims:
  - C-DBNAME: database name present.
  - C-DEFAULT-POSTGRES: no name and no service, so default `postgres`.
  - C-SERVICE-NO-DBNAME: service configured and no name, so no positional
    database argument.

The model preserves the proof-relevant axis: list order. A passing instance and
a failing instance remain distinguishable:

- Passing: `["psql", "-c", "SQL", "dbname"]`.
- Failing: `["psql", "dbname", "-c", "SQL"]`.

## Adequacy

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the formal claims. `fvk/SPEC_AUDIT.md`
compares them to `fvk/INTENT_SPEC.md`; every required behavior passes, with the
legacy public test expectation marked SUSPECT rather than authoritative.
