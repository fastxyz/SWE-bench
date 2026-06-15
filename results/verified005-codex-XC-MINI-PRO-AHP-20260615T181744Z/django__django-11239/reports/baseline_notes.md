# Baseline Notes

## Root cause

The PostgreSQL `dbshell` implementation builds a `psql` command from
`connection.get_connection_params()`, but it only forwards the database name,
user, host, port, and password. PostgreSQL connection options such as
`sslmode`, `sslrootcert`, `sslcert`, and `sslkey` are preserved in
`conn_params` by the backend, but `runshell_db()` ignored them, so `manage.py
dbshell` could not use the same TLS client certificate settings as normal ORM
connections.

## Changed files

`repo/django/db/backends/postgresql/client.py`

Added mapping from supported PostgreSQL SSL connection parameters to libpq
environment variables used by `psql`:

- `sslmode` -> `PGSSLMODE`
- `sslrootcert` -> `PGSSLROOTCERT`
- `sslcert` -> `PGSSLCERT`
- `sslkey` -> `PGSSLKEY`

The existing command-line arguments are unchanged, and `PGPASSWORD` handling is
preserved. Values are converted to strings in the same style as the existing
password environment handling.

## Assumptions and alternatives

I assumed the intended behavior is for `dbshell` to honor the PostgreSQL
connection options already accepted in `DATABASES['default']['OPTIONS']`,
matching the issue's example. I included `sslmode` and `sslrootcert` along with
the requested client certificate and key because they are part of the same
mutual TLS configuration and are passed through `get_connection_params()`.

I considered adding SSL options to the `psql` argument list, but `psql` relies
on libpq connection parameters for these settings and the existing Django code
already uses environment variables for connection secrets. Using libpq
environment variables keeps the change small and avoids changing the visible
command shape that existing tests assert.

I did not modify tests or run the test suite, per the benchmark instructions.
