# Baseline Notes

## Root cause

`BaseDatabaseClient.runshell()` treats the environment returned by a backend as optional: when a backend returns a non-empty mapping, Django merges that mapping into `os.environ` and passes the merged environment to `subprocess.run()`. When the backend returns `None`, `subprocess.run()` inherits the current process environment.

The PostgreSQL backend always returned a dictionary from `settings_to_cmd_args_env()`, even when it had no PostgreSQL-specific environment variables to add. In the no-overrides case this was `{}`. Because `{}` is falsey, the shared runner skipped the merge but still passed the empty dictionary through to `subprocess.run()`, causing `psql` to run with an empty environment instead of inheriting `os.environ`.

## Changed files

`repo/django/db/backends/postgresql/client.py`

Changed `DatabaseClient.settings_to_cmd_args_env()` to return `None` when the computed PostgreSQL environment mapping is empty. It still returns a dictionary when settings or options require `PGPASSWORD`, `PGSERVICE`, `PGSSLMODE`, certificate paths, keys, or `PGPASSFILE`.

## Assumptions and alternatives

I assumed the intended backend contract is the one already followed by the MySQL, SQLite, and Oracle clients: return `None` when there are no environment variables to add, and return a mapping only for actual overrides.

I considered changing `BaseDatabaseClient.runshell()` to coerce any falsey environment value to `None`. That would also prevent an empty environment from being passed to `subprocess.run()`, but it would leave PostgreSQL's return value inconsistent with the other built-in clients and with the reported root cause. The targeted PostgreSQL change fixes the described issue without changing the shared runner behavior for third-party backends.
