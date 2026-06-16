# Constructed Proof

Status: constructed, not machine-checked. No K tooling, tests, Python, or project code were executed.

## Proof Summary

The audited code has no loops. The proof is a case analysis over the value returned by `settings_to_cmd_args_env()` and consumed by `BaseDatabaseClient.runshell()`:

- PostgreSQL no-overrides case: the local `env` map remains empty, so `env or None` returns `None`.
- PostgreSQL with-overrides case: the local `env` map is non-empty, so `env or None` returns the mapping.
- Base runner `None` case: falsey branch normalizes to `None`; subprocess inherits `os.environ`.
- Base runner empty-map case: falsey branch normalizes to `None`; subprocess inherits `os.environ`.
- Base runner non-empty-map case: truthy branch overlays the mapping onto `os.environ`.

## Symbolic Proof Sketch

### PG-NO-OVERRIDES

Initial symbolic state:

```text
env = {}
passwd, service, sslmode, sslrootcert, sslcert, sslkey, passfile are all falsey
```

Each conditional env assignment is skipped. Therefore `env == {}` at the return. Python evaluates `env or None` to `None`. This reaches the `NoEnv` postcondition.

### PG-WITH-OVERRIDES

Representative password state:

```text
passwd = PW, with PW truthy
all other env-producing fields falsey
```

The password branch executes and produces `env == {'PGPASSWORD': str(PW)}`. The mapping is non-empty, so `env or None` returns that mapping. The same branch pattern applies to `service`, SSL fields, and `passfile`; each selected field adds one mapping entry and keeps the result truthy.

### RUNSHELL-NONE

Initial symbolic state:

```text
settings_to_cmd_args_env(...) returns (args, None)
```

The `if env` guard is false. V2 executes the `else` branch and assigns `env = None`. `subprocess.run(args, env=None, check=True)` inherits the current process environment.

### RUNSHELL-EMPTY

Initial symbolic state:

```text
settings_to_cmd_args_env(...) returns (args, {})
```

The `if env` guard is false. V2 executes the `else` branch and assigns `env = None`. This removes the V1 counterexample where `{}` reached `subprocess.run()` unchanged.

### RUNSHELL-NONEMPTY

Initial symbolic state:

```text
settings_to_cmd_args_env(...) returns (args, E), where E is non-empty
```

The `if env` guard is true. The existing branch computes `{**os.environ, **E}`. The V2 edit does not change this branch, so backend overrides are still overlaid onto the inherited environment.

## Proof Obligations Discharged

- PO-PG-NO-OVERRIDES: discharged by PostgreSQL `env or None`.
- PO-PG-WITH-OVERRIDES: discharged because non-empty mappings remain truthy.
- PO-RUNSHELL-NONE: discharged by the base runner falsey branch setting `env = None`.
- PO-RUNSHELL-EMPTY: discharged by the same falsey branch; this is the V2 improvement over V1.
- PO-RUNSHELL-NONEMPTY: discharged by the unchanged truthy merge branch.
- PO-ARGS-FRAME: discharged syntactically because no argument-building lines were changed.

## Machine-Check Commands

These commands are the recorded FVK commands. They were not executed.

```sh
kompile fvk/mini-python-dbshell.k --backend haskell
kast --backend haskell fvk/dbshell-env-spec.k
kprove fvk/dbshell-env-spec.k
```

Expected result after machine checking:

```text
#Top
```

## Test Guidance

Do not delete tests based on this constructed proof alone. After machine checking, unit tests that assert individual in-domain environment cases would be candidates for redundancy, but integration tests for `dbshell` subprocess invocation should be kept. Visible tests expecting `{}` for PostgreSQL no-overrides are stale relative to the public issue and should be updated by maintainers, not preserved as intent.
