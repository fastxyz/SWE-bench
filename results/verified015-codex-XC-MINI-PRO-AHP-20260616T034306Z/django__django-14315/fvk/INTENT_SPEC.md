# Intent Spec

Status: constructed from public evidence only; current code is treated as the candidate to check.

## Required Behaviors

1. `BaseDatabaseClient.runshell()` must not pass an empty environment to the database client process when the backend has no environment overrides. The subprocess must inherit the current process environment in that case.

2. `DatabaseClient.settings_to_cmd_args_env()` for PostgreSQL must return `None` for its environment component when no PostgreSQL-specific environment variables are needed.

3. `DatabaseClient.settings_to_cmd_args_env()` for PostgreSQL must continue returning a non-empty environment mapping when settings or options require PostgreSQL client variables such as `PGPASSWORD`, `PGSERVICE`, `PGSSLMODE`, `PGSSLROOTCERT`, `PGSSLCERT`, `PGSSLKEY`, or `PGPASSFILE`.

4. PostgreSQL command argument construction is not the reported defect. The fix must preserve the existing argument behavior for user, host, port, database name, default database selection, and extra parameters.

5. The base runner's public handoff shape is `(args, optional_env)`. A `None` environment means `subprocess.run()` inherits `os.environ`; a non-empty mapping means Django overlays the mapping onto `os.environ` before invoking `subprocess.run()`.

## Boundary Conditions

- Empty PostgreSQL override set: expected env result is `None`, not `{}`.
- Non-empty PostgreSQL override set: expected env result is the exact mapping of selected PostgreSQL environment variables to their string values.
- Backend returns `None`: base runner should pass `env=None` to `subprocess.run()`.
- Backend returns `{}`: base runner should also pass `env=None`; passing `{}` produces the reported empty-environment bug.
- Backend returns a non-empty mapping: base runner should pass `{**os.environ, **mapping}`.

## Default-Domain Assumptions

- Python's `subprocess.run(..., env=None)` inherits the parent process environment.
- Python's dictionary unpacking `{**os.environ, **env}` preserves all current environment keys except those explicitly overridden by `env`.
- Truthiness follows normal Python conventions: `None` and `{}` are falsey, non-empty mappings are truthy, and non-empty strings are truthy.
