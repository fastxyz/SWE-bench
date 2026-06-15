# Intent Spec

Status: constructed from public intent only, before accepting V1 behavior as the specification.

## Required behavior

1. PostgreSQL `dbshell` must support the mutual TLS connection settings shown in the issue:
   `sslmode`, `sslrootcert`, `sslcert`, and `sslkey`.
2. The source of these values is `DATABASES['default']['OPTIONS']`, which the PostgreSQL backend
   already places in `conn_params` through `get_connection_params()`.
3. The `psql` process launched by `runshell_db()` must receive the corresponding libpq connection
   settings:
   - `sslmode` as `PGSSLMODE`
   - `sslrootcert` as `PGSSLROOTCERT`
   - `sslcert` as `PGSSLCERT`
   - `sslkey` as `PGSSLKEY`
4. Existing non-SSL dbshell behavior must be preserved: executable name, user, host, port,
   database argument order, password handling through `PGPASSWORD`, `check=True`, and restoration
   of the original SIGINT handler.

## Domain

The verified domain is a `conn_params` mapping produced by PostgreSQL
`get_connection_params()` with optional non-empty string or stringable values for `host`,
`port`, `database`, `user`, `password`, `sslmode`, `sslrootcert`, `sslcert`, and `sslkey`.

## Explicitly out of scope

The issue does not require forwarding every possible libpq option, nor changing the public
signature of `runshell_db()`, nor replacing the current `psql` argument shape with a connection
string.
