# FVK Spec

Status: constructed, not machine-checked.

## Scope

The audited behavior is the database-client environment handoff for `dbshell`:

- `repo/django/db/backends/postgresql/client.py::DatabaseClient.settings_to_cmd_args_env()`
- `repo/django/db/backends/base/client.py::BaseDatabaseClient.runshell()`

There are no loops in the audited slice. The proof obligations are branch obligations over falsey/empty/non-empty environment values and partial correctness of the subprocess environment selected by the code.

## Public Intent Ledger

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The critical obligations are:

- The issue states that `runshell` does not respect `os.environ` in some cases.
- The issue identifies PostgreSQL returning `{}` instead of `None` for no environment overrides.
- The issue identifies the observable consequence: an empty environment is passed to `subprocess`.
- Django's release note describes the second result from `settings_to_cmd_args_env()` as optional.
- Other built-in clients use `None` for the no-env case.

Visible PostgreSQL tests expecting `{}` are classified as SUSPECT legacy evidence because they encode the behavior the public issue reports as the defect.

## Function Contracts

### PostgreSQL `settings_to_cmd_args_env()`

Precondition:

- `settings_dict` is a Django database settings mapping.
- `parameters` is an iterable/list of command-line parameters.

Postconditions:

- The returned command args preserve existing PostgreSQL construction: executable `psql`, optional `-U`, `-h`, `-p`, database/default database behavior, and appended parameters.
- The returned env is `None` when the computed PostgreSQL environment mapping is empty.
- The returned env is a non-empty dict when at least one PostgreSQL environment value is selected.
- Each selected PostgreSQL environment value is stringified as before.

### Base `runshell()`

Precondition:

- `settings_to_cmd_args_env()` returns `(args, env)` where `env` is either `None` or a mapping of environment variables to add.

Postconditions:

- If `env` is `None`, `subprocess.run()` is called with `env=None`.
- If `env` is `{}`, `subprocess.run()` is also called with `env=None`.
- If `env` is non-empty, `subprocess.run()` is called with `{**os.environ, **env}`.
- `check=True` and `args` behavior are unchanged.

## Formal Files

- `fvk/mini-python-dbshell.k`: minimal K fragment for `NoEnv`, `Env(Map)`, `Inherit`, `Explicit(Map)`, PostgreSQL env normalization, and the base runner environment handoff.
- `fvk/dbshell-env-spec.k`: reachability claims for the no-overrides, with-overrides, and base-runner handoff cases.

## Exact Commands To Machine-Check Later

These commands are recorded only; they were not executed in this environment.

```sh
kompile fvk/mini-python-dbshell.k --backend haskell
kast --backend haskell fvk/dbshell-env-spec.k
kprove fvk/dbshell-env-spec.k
```
