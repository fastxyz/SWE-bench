# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Symbols

No public symbol signature changed.

`django.db.backends.postgresql.client.DatabaseClient.settings_to_cmd_args_env()`
keeps the same classmethod signature and still returns `(args, env)`.

`DatabaseClient.runshell()` is unchanged.

`django.core.management.commands.dbshell.Command` is unchanged and still passes
the parsed `parameters` list through to the selected backend client.

## Callers and Overrides

The changed behavior is internal to PostgreSQL argument construction. The base
client still consumes the returned `args` list via `subprocess.run(args, env=env,
check=True)`.

Other backend clients have independent `settings_to_cmd_args_env()`
implementations and were not changed.

## Compatibility Result

PASS. V1 changes only the relative order of PostgreSQL `parameters` and the
positional database argument. No public call shape, return shape, subclass
contract, or cross-backend dispatch contract changed.
