# Constructed Proof

Status: constructed, not machine-checked.

## Target

`DatabaseClient.settings_to_cmd_args_env()` in
`repo/django/db/backends/postgresql/client.py`.

The proof covers the PostgreSQL `dbshell` argument ordering defect described in
the issue. There are no loops or recursion in the audited code path, so the
proof is straight-line symbolic execution with branch splitting over dbname and
service presence.

## Formal Artifacts

- Semantics: `fvk/mini-postgresql-dbshell.k`
- Claims: `fvk/postgresql-dbshell-spec.k`

Commands to machine-check later, not executed here:

```sh
kompile fvk/mini-postgresql-dbshell.k --backend haskell
kast --backend haskell fvk/postgresql-dbshell-spec.k
kprove fvk/postgresql-dbshell-spec.k
```

Expected machine-check result after a valid K setup: `#Top` for the three claims.

## Proof Sketch

### C-DBNAME

Initial symbolic state:

`build(HASUSER, HASHOST, HASPORT, true, HASSERVICE, PARAMS)`.

The mini semantics rewrites this in one rule to:

`["psql"] + userOpt(HASUSER) + hostOpt(HASHOST) + portOpt(HASPORT) + PARAMS + dbArg(true, HASSERVICE)`.

The `dbArg(true, _)` rule rewrites to `[dbname]`, so the final symbolic list is:

`["psql"] + userOpt(HASUSER) + hostOpt(HASHOST) + portOpt(HASPORT) + PARAMS + [dbname]`.

This proves PO-01: for every `PARAMS`, the configured positional dbname is after
`PARAMS`.

### C-DEFAULT-POSTGRES

Initial symbolic state:

`build(HASUSER, HASHOST, HASPORT, false, false, PARAMS)`.

The main build rule yields:

`["psql"] + userOpt(HASUSER) + hostOpt(HASHOST) + portOpt(HASPORT) + PARAMS + dbArg(false, false)`.

The `dbArg(false, false)` rule rewrites to `[postgres]`, so the default database
is also after `PARAMS`. This proves PO-02.

### C-SERVICE-NO-DBNAME

Initial symbolic state:

`build(HASUSER, HASHOST, HASPORT, false, true, PARAMS)`.

The main build rule yields:

`["psql"] + userOpt(HASUSER) + hostOpt(HASHOST) + portOpt(HASPORT) + PARAMS + dbArg(false, true)`.

The `dbArg(false, true)` rule rewrites to the empty list, so no positional
database argument is introduced. This proves PO-03.

## Source Correspondence

The V1 source executes the same order:

1. `args = [cls.executable_name]`.
2. Append configured `-U`, `-h`, and `-p` options.
3. `args.extend(parameters)`.
4. If `dbname` is truthy, append `dbname`.

If `NAME` is absent and service is absent, the source first sets
`dbname = "postgres"`, which is covered by C-DEFAULT-POSTGRES. If service is
present and `NAME` is absent, `dbname` remains false, which is covered by
C-SERVICE-NO-DBNAME.

Environment construction occurs after the argument list and does not depend on
the relative order of `parameters` and `dbname`, discharging PO-04 by frame
inspection.

## Test Recommendation

No test removal is recommended. The existing public PostgreSQL
`test_parameters` expectation is classified as SUSPECT because it preserves the
legacy order contradicted by the issue. A future test update should assert that
PostgreSQL parameters precede the dbname, for example:

`settings_to_cmd_args_env({"NAME": "dbname"}, ["-c", "select 1"])`
returns `["psql", "-c", "select 1", "dbname"]`.

Per the task constraints, no tests were edited or run.

## Residual Risk

This proof is constructed, not machine-checked. The K fragment is deliberately
small and models the order-sensitive argument-list behavior, not full Python or
full Django. The abstraction is adequate for this issue because it distinguishes
the passing list shape from the failing list shape.
