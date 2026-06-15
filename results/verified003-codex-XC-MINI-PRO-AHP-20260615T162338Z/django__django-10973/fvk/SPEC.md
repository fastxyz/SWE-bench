# FVK Specification for django__django-10973

Status: constructed, not machine-checked. No tests, Python, or K tooling were
executed.

## Scope

Audited unit:

- `repo/django/db/backends/postgresql/client.py`
- `DatabaseClient.runshell_db(cls, conn_params)`
- Indirect public entrypoint: `DatabaseClient.runshell(self)`, called by
  `django.core.management.commands.dbshell.Command.handle()`

The observable under audit is the PostgreSQL dbshell subprocess launch:
constructed argv, subprocess environment, subprocess API, and SIGINT handler
restoration.

## Intent Spec

I1. PostgreSQL dbshell must invoke the `psql` command-line client with the same
database connection arguments Django already supported.

I2. When a PostgreSQL password is configured, Django must pass it to the client
subprocess through `PGPASSWORD`.

I3. The password environment must be supplied as a custom subprocess environment
instead of mutating process-global `os.environ` with `PGPASSFILE`.

I4. The client invocation must use `subprocess.run()`. Since the previous
implementation used `subprocess.check_call()`, the replacement must preserve
nonzero-exit error behavior by passing `check=True`.

I5. Existing SIGINT behavior must be preserved: ignore SIGINT in Python while
the client subprocess runs, then restore the original handler even when the
subprocess raises.

I6. Public call compatibility must be preserved: `runshell_db(cls,
conn_params)` and `runshell(self)` keep their signatures and return no meaningful
value.

## Public Evidence Ledger

E1. Source: `benchmark/PROBLEM.md`

Quote: "Use subprocess.run and PGPASSWORD for client in postgres backend"

Obligation: `runshell_db()` invokes the PostgreSQL client with
`subprocess.run()` and passes configured passwords through `PGPASSWORD`.

Status: encoded in PO-2 and PO-3.

E2. Source: `benchmark/PROBLEM.md`

Quote: "This function allows you to pass a custom environment for the
subprocess."

Obligation: construct an environment mapping and pass it with the subprocess
call; do not rely on process-global mutation for password delivery.

Status: encoded in PO-2.

E3. Source: `benchmark/PROBLEM.md`

Quote: "Using this in django.db.backends.postgres.client to set PGPASSWORD
simplifies the code and makes it more reliable."

Obligation: remove the temporary `.pgpass`/`PGPASSFILE` path rather than
retaining it as a fallback.

Status: encoded in PO-2 and Finding F-2.

E4. Source: `repo/docs/ref/django-admin.txt`

Quote: "`dbshell` ... with the connection parameters specified in your USER,
PASSWORD, etc., settings" and "For PostgreSQL, this runs the `psql`
command-line client."

Obligation: preserve psql command construction from database, user, host, port,
and password settings.

Status: encoded in PO-1 and PO-2.

E5. Source: `repo/tests/dbshell/test_postgresql.py`

Quote: existing assertions expect argv such as `['psql', '-U', user, '-h',
host, '-p', port, dbname]`.

Obligation: argv construction is public behavior to preserve.

Status: encoded in PO-1.

E6. Source: `repo/tests/dbshell/test_postgresql.py`

Quote: existing helper describes "the content of the file pointed by
environment PGPASSFILE".

Obligation: SUSPECT legacy-test evidence. This conflicts with E1-E3 because the
issue explicitly asks to replace that mechanism with `PGPASSWORD`.

Status: recorded as Finding F-2 and not used as a blocking spec obligation.

E7. Source: `repo/tests/dbshell/test_postgresql.py`

Quote: "SIGINT is ignored in Python and passed to psql to abort quries" and the
test checks restoration after `runshell_db({})`.

Obligation: preserve SIGINT ignore/restore framing across the subprocess call.

Status: encoded in PO-4.

E8. Source: `repo/django/core/management/commands/dbshell.py`

Quote: `connection.client.runshell()`.

Obligation: no public signature or dispatch change to `runshell()`.

Status: encoded in PO-5.

## Formal Contract

Let `ENV0` be the process environment mapping at method entry and `SIG0` be the
SIGINT handler at method entry. Let connection parameters be:

- `DB = conn_params.get('database', '')`
- `USER = conn_params.get('user', '')`
- `PASS = conn_params.get('password', '')`
- `HOST = conn_params.get('host', '')`
- `PORT = conn_params.get('port', '')`

Preconditions:

- `conn_params` is a mapping with optional string-like PostgreSQL connection
  values. `PORT` may be any value with a stable `str(PORT)`.
- `os.environ.copy()`, `signal.getsignal()`, `signal.signal()`, and
  `subprocess.run()` obey their Python standard-library contracts.
- External `psql`/libpq behavior is outside the unit proof, except for the
  public issue's intent that `PGPASSWORD` is the accepted password channel.

Postconditions:

- The subprocess argv is exactly:
  `[DatabaseClient.executable_name]`, then `['-U', USER]` iff `USER` is truthy,
  then `['-h', HOST]` iff `HOST` is truthy, then `['-p', str(PORT)]` iff `PORT`
  is truthy, then `[DB]`.
- The subprocess environment is a copy of `ENV0`, except that if `PASS` is
  truthy then the subprocess environment maps `PGPASSWORD` to `PASS`.
- `os.environ` is not assigned `PGPASSFILE` by this method and is not mutated by
  the password-delivery path.
- `subprocess.run(argv, check=True, env=subprocess_env)` is invoked exactly
  once after SIGINT is set to `SIG_IGN`.
- The SIGINT handler is restored to `SIG0` in the `finally` path whether
  `subprocess.run()` returns normally or raises.
- `runshell()` continues to delegate to `DatabaseClient.runshell_db()` with
  `self.connection.get_connection_params()`.

Frame conditions:

- No test files are changed.
- No public Django management command API changes.
- No behavior of non-PostgreSQL database clients is changed.

## K Claim Sketch

This is the constructed formal core in compact form. It abstracts Python's
external subprocess and signal APIs into observable events; the proof is over
the event shape, environment map, and restored signal cell, not over `psql`
itself.

```k
// SPEC-PROVENANCE:
// - E1/E2/E3: use subprocess.run with PGPASSWORD in a custom env.
// - E4/E5: preserve argv construction.
// - E7: preserve SIGINT ignore/restore.
claim <k> runshellDb(DB, USER, PASS, HOST, PORT) => .K </k>
      <environ> ENV0:Map => ENV0 </environ>
      <sigint> SIG0:String => SIG0 </sigint>
      <events> .List =>
        ListItem(setSigint("SIG_IGN"))
        ListItem(run(
          makePostgresArgv("psql", DB, USER, HOST, PORT),
          makePostgresEnv(ENV0, PASS),
          true))
        ListItem(setSigint(SIG0))
      </events>
  requires validConnParams(DB, USER, PASS, HOST, PORT)
  ensures noPgpassfileMutation(ENV0)
  [all-path]
```

Auxiliary functions:

- `makePostgresArgv()` emits optional `-U`, `-h`, and `-p` pairs exactly when
  the corresponding value is truthy, with `PORT` rendered through `str()`.
- `makePostgresEnv(ENV0, PASS)` is `ENV0["PGPASSWORD" <- PASS]` when `PASS` is
  truthy, otherwise `ENV0`.
- `noPgpassfileMutation(ENV0)` states the method itself performs no
  `os.environ['PGPASSFILE'] = ...` or deletion.

The full proof obligations are listed in `fvk/PROOF_OBLIGATIONS.md`.
