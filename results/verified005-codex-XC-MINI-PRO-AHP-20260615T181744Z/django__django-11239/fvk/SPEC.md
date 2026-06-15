# SPEC

Status: constructed, not machine-checked.

## Target

`django.db.backends.postgresql.client.DatabaseClient.runshell_db(cls, conn_params)`

The audited observable is the `psql` subprocess invocation: argument list,
subprocess environment, `check=True`, and SIGINT handling.

## Intent ledger summary

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

- E1: The issue title requires PostgreSQL dbshell support for client certificate
  and key.
- E2: The issue describes mutual TLS as requiring a server certificate, client
  certificate, and client key.
- E3: The concrete example uses `sslmode`, `sslrootcert`, `sslcert`, and
  `sslkey` inside `DATABASES['default']['OPTIONS']`.
- E4: PostgreSQL `get_connection_params()` already includes `OPTIONS` in
  `conn_params`.
- E5: Existing dbshell behavior for `psql` args and `PGPASSWORD` must be
  preserved.

## Contract

For any in-domain `conn_params` produced by the PostgreSQL backend:

1. `args` begins with `psql`.
2. If `user` is present and truthy, append `-U` and `user`.
3. If `host` is present and truthy, append `-h` and `host`.
4. If `port` is present and truthy, append `-p` and `str(port)`.
5. Append `database`, defaulting to an empty string when missing, matching
   legacy behavior.
6. Copy `os.environ` to form the subprocess environment.
7. If `password` is present and truthy, set `PGPASSWORD` to `str(password)`.
8. If `sslmode` is present and truthy, set `PGSSLMODE` to `str(sslmode)`.
9. If `sslrootcert` is present and truthy, set `PGSSLROOTCERT` to
   `str(sslrootcert)`.
10. If `sslcert` is present and truthy, set `PGSSLCERT` to `str(sslcert)`.
11. If `sslkey` is present and truthy, set `PGSSLKEY` to `str(sslkey)`.
12. Preserve unrelated environment variables from the copied process
    environment.
13. Run `subprocess.run(args, check=True, env=subprocess_env)`.
14. Ignore SIGINT while `psql` runs and restore the original SIGINT handler in
    all completion paths through the `finally` block.

## Formal artifacts

- `fvk/mini-dbshell.k`: abstract K semantics for the dbshell observable.
- `fvk/postgresql-dbshell-spec.k`: K-style reachability claim for the target.
- `fvk/INTENT_SPEC.md`: intent-only obligations.
- `fvk/FORMAL_SPEC_ENGLISH.md`: English paraphrase of the K claims.
- `fvk/SPEC_AUDIT.md`: adequacy gate.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: public API and callsite audit.

## V1 audit conclusion

V1 satisfies this spec by inspection of `repo/django/db/backends/postgresql/client.py`.
Lines 33-41 map each issue-named SSL connection parameter to the correct libpq
environment variable without changing the existing argument construction,
password handling, subprocess call, or SIGINT restoration.
