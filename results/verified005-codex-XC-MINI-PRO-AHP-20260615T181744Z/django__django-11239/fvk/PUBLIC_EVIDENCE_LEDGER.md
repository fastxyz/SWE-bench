# Public Evidence Ledger

## E1: Issue title

- Source: prompt
- Evidence: "Add support for postgresql client certificates and key to dbshell."
- Obligation: `dbshell` must pass PostgreSQL client certificate and key settings to `psql`.
- Status: encoded in SPEC and K claim as `sslcert -> PGSSLCERT` and `sslkey -> PGSSLKEY`.

## E2: Mutual TLS description

- Source: prompt
- Evidence: "This involves specifying a server certificate, client certificate, and client key when connecting."
- Obligation: the complete mutual TLS group shown by the issue includes server CA, client cert,
  and client key.
- Status: encoded as `sslrootcert`, `sslcert`, and `sslkey` obligations.

## E3: Concrete Django settings example

- Source: prompt
- Evidence: the example `OPTIONS` contains `sslmode`, `sslrootcert`, `sslcert`, and `sslkey`.
- Obligation: each named option must be honored by `dbshell`, not only normal ORM connections.
- Status: encoded as the four SSL environment variables in SPEC and claims.

## E4: Existing backend behavior

- Source: implementation
- Evidence: `get_connection_params()` builds `conn_params = {'database': NAME, **OPTIONS}`.
- Obligation: `runshell_db()` can and should consume SSL keys from `conn_params`; no additional
  settings plumbing is needed.
- Status: used as implementation evidence for the source of values, not as the expected result.

## E5: Existing dbshell contract

- Source: public tests / implementation
- Evidence: visible dbshell tests assert `['psql', '-U', user, '-h', host, '-p', port, dbname]`
  and `PGPASSWORD` handling.
- Obligation: adding TLS support must not change the established command argument order or
  password environment behavior.
- Status: encoded as frame conditions in SPEC and proof obligations.
