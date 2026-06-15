# FVK Proof Obligations

Status: constructed, not machine-checked. The commands that would machine-check
the K sketch are recorded in `fvk/PROOF.md`; they were not executed.

## PO-1: PostgreSQL argv Construction

Intent source: SPEC E4, E5.

Claim:

For all in-domain `conn_params`, `runshell_db()` constructs:

```text
[executable_name]
+ (['-U', user] if user else [])
+ (['-h', host] if host else [])
+ (['-p', str(port)] if port else [])
+ [database]
```

with `executable_name == 'psql'` and `database == conn_params.get('database',
'')`.

Discharge:

V1 preserves the pre-existing command construction lines and only changes the
password-delivery and subprocess invocation mechanism.

Status: discharged by source inspection and symbolic path proof.

Related findings: F-1.

## PO-2: Subprocess Environment Uses `PGPASSWORD`

Intent source: SPEC E1, E2, E3.

Claim:

For entry environment `ENV0` and password `PASS`:

- `subprocess_env == ENV0.copy()` when `PASS` is falsey.
- `subprocess_env == ENV0.copy()` overridden with
  `PGPASSWORD -> PASS` when `PASS` is truthy.
- The method does not assign `os.environ['PGPASSFILE']` and does not create a
  temporary `.pgpass` file.

Discharge:

V1 computes `env = os.environ.copy()`, conditionally sets
`env['PGPASSWORD'] = passwd`, and passes that `env` to the subprocess call. The
old `_escape_pgpass()` and `NamedTemporaryFile` path is absent.

Status: discharged by source inspection and symbolic path proof.

Related findings: F-1, F-2.

## PO-3: Checked `subprocess.run()` Invocation

Intent source: SPEC E1 and compatibility with the previous `check_call()`
behavior.

Claim:

`runshell_db()` invokes the client exactly once with:

```python
subprocess.run(args, check=True, env=env)
```

The checked invocation raises `subprocess.CalledProcessError` on nonzero client
exit, preserving the relevant behavior of `subprocess.check_call(args)`.

Discharge:

The V1 call site is exactly `subprocess.run(args, check=True, env=env)`.

Status: discharged by source inspection and standard-library contract
assumption.

Related findings: F-1, F-4.

## PO-4: SIGINT Handler Is Restored

Intent source: SPEC E7.

Claim:

If `SIG0 = signal.getsignal(signal.SIGINT)` at method entry, the method restores
`signal.SIGINT` to `SIG0` after the subprocess path, both when
`subprocess.run()` returns and when it raises.

Discharge:

The `signal.signal(signal.SIGINT, signal.SIG_IGN)` call remains inside a
`try`, and the restoration remains in the corresponding `finally`.

Status: discharged by structured-control proof over `try/finally`.

Related findings: F-3.

## PO-5: Public Call Compatibility

Intent source: SPEC E8 and public method shape.

Claim:

The patch does not change:

- `DatabaseClient.runshell_db(cls, conn_params)`
- `DatabaseClient.runshell(self)`
- `django.core.management.commands.dbshell.Command.handle()` dispatch through
  `connection.client.runshell()`

Discharge:

V1 changes only the implementation body of `runshell_db()`. Signatures and
callers remain unchanged.

Status: discharged by public callsite search.

Related findings: F-4.

## PO-6: Legacy `.pgpass` Public Tests Are Suspect, Not Binding

Intent source: SPEC E6 plus FVK suspect-legacy-test rule.

Claim:

A public test expectation that requires `PGPASSFILE` and `.pgpass` contents
must not be used as the formal postcondition because it contradicts the public
issue's explicit request to use `PGPASSWORD` with `subprocess.run(env=...)`.

Discharge:

The issue text is newer and directly names the replacement mechanism. The
formal postcondition follows SPEC E1-E3; SPEC E6 is recorded as conflict
evidence in Finding F-2.

Status: discharged as an adequacy-gate decision.

Related findings: F-2.

## PO-7: External PostgreSQL Client Boundary

Intent source: SPEC E1-E4.

Claim:

The Django-side proof must show that `PGPASSWORD` reaches the child process
environment. It need not prove the external `psql` binary's behavior after
process launch.

Discharge:

The formal model treats the subprocess call as an event containing argv, env,
and `check=True`. External client semantics are outside this source-level fix.

Status: discharged as a proof boundary.

Related findings: F-6.

## PO-8: Domain of Connection Parameter Values

Intent source: `get_connection_params()` and public tests.

Claim:

The audited domain consists of PostgreSQL connection parameters with
string-like `database`, `user`, `password`, and `host` values and a `port` value
accepted by `str(port)`.

Discharge:

Django's PostgreSQL `get_connection_params()` sources these values from
database settings, and public tests pass strings. The old `.pgpass`
implementation also assumed string password fragments.

Status: accepted domain precondition.

Related findings: F-5.
