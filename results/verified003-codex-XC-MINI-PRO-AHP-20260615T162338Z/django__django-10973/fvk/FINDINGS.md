# FVK Findings

Status: constructed, not machine-checked. These findings are derived from the
public issue, source inspection, and formal proof obligations. No tests or code
were executed.

## F-1: V1 Satisfies the Primary Password-Delivery Intent

Input:

```python
{
    'database': 'dbname',
    'user': 'someuser',
    'password': 'somepassword',
    'host': 'somehost',
    'port': '444',
}
```

Expected from public intent:

- Invoke `psql` through `subprocess.run()`.
- Pass `PGPASSWORD=somepassword` in the subprocess environment.
- Preserve argv construction:
  `['psql', '-U', 'someuser', '-h', 'somehost', '-p', '444', 'dbname']`.

Observed in V1 source:

- `env = os.environ.copy()`
- `env['PGPASSWORD'] = passwd` when `passwd` is truthy
- `subprocess.run(args, check=True, env=env)`
- Existing optional argv construction is unchanged.

Classification: confirm V1, no code change required.

Related proof obligations: PO-1, PO-2, PO-3.

## F-2: Existing Public Tests Encode the Legacy `.pgpass` Mechanism

Input:

```python
{
    'database': 'dbname',
    'user': 'some:user',
    'password': 'some:password',
    'host': '::1',
    'port': '444',
}
```

Legacy expectation in public tests:

- Read a temporary file through `os.environ['PGPASSFILE']`.
- Assert escaped `.pgpass` contents such as
  `\\:\\:1:444:dbname:some\\:user:some\\:password`.

Expected from current public issue:

- Use `PGPASSWORD` in the subprocess environment instead of `.pgpass`.
- Avoid the temporary file and process-global `PGPASSFILE` path.

Observed in V1 source:

- `_escape_pgpass()` and `NamedTemporaryFile` are removed.
- No code assigns or deletes `os.environ['PGPASSFILE']`.

Classification: SUSPECT legacy-test evidence, not a code bug. The tests would
need to be updated outside this task to mock `subprocess.run()` and assert
`env['PGPASSWORD']`; this task forbids modifying tests.

Related proof obligations: PO-2, PO-6.

## F-3: SIGINT Restoration Is Preserved Across the New Subprocess API

Input:

```python
{}
```

Expected from public tests and existing code comments:

- Save the current SIGINT handler.
- Set SIGINT to `SIG_IGN` while the client subprocess runs.
- Restore the original SIGINT handler afterward.

Observed in V1 source:

- `sigint_handler = signal.getsignal(signal.SIGINT)` still precedes the
  `try`.
- `signal.signal(signal.SIGINT, signal.SIG_IGN)` still occurs immediately
  before the subprocess call.
- The `finally` block still restores `sigint_handler`.

Classification: confirm V1, no code change required.

Related proof obligations: PO-4.

## F-4: Public API Compatibility Is Preserved

Input:

```python
django.core.management.commands.dbshell.Command.handle(database='default')
```

Expected from public callsites:

- `connection.client.runshell()` remains callable without new arguments.
- `runshell()` delegates to `runshell_db(self.connection.get_connection_params())`.
- `runshell_db(cls, conn_params)` remains callable with the same classmethod
  signature.

Observed in V1 source:

- Neither method signature changed.
- The management command callsite still reaches the same `runshell()` method.
- The subprocess failure mode remains `CalledProcessError` on nonzero exit
  because `subprocess.run(..., check=True)` matches `check_call()`'s checked
  behavior.

Classification: confirm V1, no code change required.

Related proof obligations: PO-3, PO-5.

## F-5: Password Value Type Is an Explicit Domain Assumption

Input:

```python
{'password': object()}
```

Expected from the audited public contract:

- Connection parameters come from Django database settings and public tests,
  where password values are strings.

Observed in V1 source:

- `env['PGPASSWORD'] = passwd` assumes `passwd` is suitable for a subprocess
  environment mapping.

Classification: residual domain assumption, not a code bug for this issue. The
pre-existing `.pgpass` implementation also assumed string password fragments by
calling `_escape_pgpass(passwd)`. A future hardening change could coerce with
`str(passwd)`, but the FVK audit did not find public intent requiring broader
input types for `runshell_db()`.

Related proof obligations: PO-8.

## F-6: External `psql`/libpq Interpretation of `PGPASSWORD` Is Out of Scope

Input:

```python
{'password': 'somepassword'}
```

Expected from public issue:

- `PGPASSWORD` is the intended PostgreSQL client password channel.

Observed/proved in V1 source:

- Django supplies `PGPASSWORD` to the child process environment.

Not proved:

- The external `psql` executable's interpretation of `PGPASSWORD`.

Classification: proof capability boundary, not a V1 code bug. The public issue
itself supplies the domain fact that `PGPASSWORD` is the desired channel.

Related proof obligations: PO-7.

## Proof-Derived Findings From `/verify`

No proof-derived code bugs were found. The constructed proof discharges the
audited Django-side obligations for argv shape, subprocess environment shape,
checked subprocess invocation, SIGINT restoration, and public call compatibility,
subject to the domain and external-tool boundaries in F-5 and F-6.
