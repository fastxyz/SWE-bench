# Public Compatibility Audit

## Changed Symbols

`django.db.backends.postgresql.client.DatabaseClient.settings_to_cmd_args_env()`

- Signature: unchanged.
- Return shape: still a two-tuple `(args, env)`.
- Compatibility effect: the env component changes from `{}` to `None` only when there are no environment overrides. This aligns PostgreSQL with MySQL, SQLite, Oracle, the docs' optional-env wording, and the public issue.
- Public callsites: `BaseDatabaseClient.runshell()` and tests/helpers that call `settings_to_cmd_args_env()` directly. Direct callers that distinguish `{}` from `None` are depending on the behavior reported as buggy.

`django.db.backends.base.client.BaseDatabaseClient.runshell()`

- Signature: unchanged.
- Return value: unchanged (`None`, as before).
- Subprocess handoff: non-empty env mappings are still merged with `os.environ`; falsey env values now normalize to `None`.
- Public override compatibility: subclasses overriding `settings_to_cmd_args_env()` remain compatible because the accepted return protocol is still `(args, optional_env)`.

## Callsite Scan

- `django/core/management/commands/dbshell.py` calls `connection.client.runshell(parameters)` and is unaffected by signatures.
- `django/db/backends/mysql/creation.py` independently applies the same truthy-env pattern for MySQL clone commands; it receives MySQL's `None` or non-empty `MYSQL_PWD` mapping and is outside this PostgreSQL `runshell()` issue.
- Built-in MySQL, SQLite, and Oracle clients already return `None` when they have no environment overrides.

## Compatibility Verdict

No public API signature changes are introduced. The only behavior change is the intended correction of an empty environment being passed to subprocesses.
