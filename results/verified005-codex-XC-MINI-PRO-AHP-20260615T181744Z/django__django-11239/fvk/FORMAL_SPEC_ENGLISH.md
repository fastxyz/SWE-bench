# Formal Spec in English

This paraphrases the nontrivial formal claims in `postgresql-dbshell-spec.k`.

## Claim DBSHELL-SSL-ENV

For any in-domain `conn_params` and initial process environment, executing `runshell_db()`
constructs a subprocess environment equal to a copy of the initial environment plus the
following updates for every present non-empty SSL connection parameter:

- `sslmode` updates `PGSSLMODE` to `str(conn_params['sslmode'])`.
- `sslrootcert` updates `PGSSLROOTCERT` to `str(conn_params['sslrootcert'])`.
- `sslcert` updates `PGSSLCERT` to `str(conn_params['sslcert'])`.
- `sslkey` updates `PGSSLKEY` to `str(conn_params['sslkey'])`.

If `password` is present and non-empty, `PGPASSWORD` is set to `str(conn_params['password'])`.

## Claim DBSHELL-ARGS-FRAME

The `psql` argument list is unchanged by SSL options. It starts with `psql`, conditionally adds
`-U user`, `-h host`, and `-p port` in that order when those values are present, then appends the
database name.

## Claim DBSHELL-SIGINT-FRAME

The original SIGINT handler is recorded before launching `psql`, SIGINT is ignored while
`psql` runs, and the original handler is restored in the `finally` block whether the subprocess
returns normally or raises.

## Claim DBSHELL-COMPATIBILITY

No public method signature, return shape, or call protocol changes. `runshell()` still calls
`DatabaseClient.runshell_db(self.connection.get_connection_params())`.
