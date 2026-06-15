# FINDINGS

Status: constructed findings; no tests or K tooling were run.

## F-001: Pre-V1 dbshell dropped mutual TLS parameters

- Classification: code bug, resolved by current V1 source.
- Evidence: issue says `dbshell` "does not support the client cert params" and
  gives `sslmode`, `sslrootcert`, `sslcert`, and `sslkey` in PostgreSQL
  `OPTIONS`.
- Input:
  `conn_params = {'database': 'dbname', 'sslmode': 'verify-ca',
  'sslrootcert': 'ca.crt', 'sslcert': 'client.crt', 'sslkey': 'client.key'}`
- Pre-V1 observed behavior:
  subprocess environment copied `os.environ` and possibly `PGPASSWORD`, but did
  not set `PGSSLMODE`, `PGSSLROOTCERT`, `PGSSLCERT`, or `PGSSLKEY`.
- Expected behavior:
  the `psql` process receives the four libpq SSL environment variables derived
  from `conn_params`.
- Current V1 status:
  resolved by `ssl_env` mapping in `client.py` lines 33-41.
- Related proof obligations:
  PO-003, PO-004, PO-005.

## F-002: V1 preserves existing dbshell observables

- Classification: confirmation after audit.
- Evidence: source inspection shows V1 leaves argument construction, `PGPASSWORD`,
  `subprocess.run(..., check=True, env=...)`, and SIGINT restoration intact.
- Input:
  any in-domain `conn_params` with existing non-SSL keys such as `user`, `host`,
  `port`, `database`, and `password`.
- Observed behavior in V1:
  existing `psql` args and password environment behavior remain unchanged; SSL
  support only adds environment variables when corresponding SSL params exist.
- Expected behavior:
  preserve legacy dbshell behavior while adding TLS support.
- Related proof obligations:
  PO-001, PO-002, PO-003, PO-006, PO-007.

## F-003: Broader arbitrary libpq option forwarding is under-specified

- Classification: underspecified intent, no V2 source change.
- Evidence: the issue describes mutual TLS and names the four SSL options in
  the example. It does not require converting all libpq connection parameters
  into a connection string or environment variables.
- Alternative considered:
  forward every unknown `conn_params` key to `psql`.
- Reason rejected:
  this would change the public subprocess interface more broadly than the
  stated bug requires and is not needed to satisfy the mutual TLS contract.
- Related proof obligations:
  PO-004, PO-007.

## F-004: Proof is constructed, not machine-checked

- Classification: proof capability / environment gap.
- Evidence: benchmark instructions prohibit running tests, Python, `kompile`, or
  `kprove`.
- Expected next step outside this session:
  run the emitted K commands and Django tests in a real execution environment.
- Related proof obligations:
  PO-008.
