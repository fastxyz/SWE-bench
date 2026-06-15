# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Claim Proved

For every in-domain `conn_params`, if `DatabaseClient.runshell_db(conn_params)`
returns or raises from the subprocess call, then the Django-side observable
behavior satisfies the contract in `fvk/SPEC.md`:

- argv is the PostgreSQL dbshell argv specified by PO-1;
- the subprocess environment is the copied entry environment with
  `PGPASSWORD` overridden exactly when a truthy password is supplied;
- the subprocess is invoked via `subprocess.run(args, check=True, env=env)`;
- the original SIGINT handler is restored through the `finally` path;
- public method signatures and management-command dispatch are unchanged.

This is a partial-correctness proof over the Python source structure and the
abstract subprocess event. It does not prove external `psql` behavior after
launch.

## Constructed K/Mini-Semantics Model

The compact K claim sketch in `fvk/SPEC.md` models:

- `<k>`: the current abstract command, `runshellDb(DB, USER, PASS, HOST, PORT)`;
- `<environ>`: process-global environment, framed unchanged;
- `<sigint>`: current SIGINT handler;
- `<events>`: emitted observable events:
  `setSigint("SIG_IGN")`, `run(argv, env, check=True)`, and
  `setSigint(SIG0)`.

The model abstracts Python library calls into trusted standard-library
contracts:

- `os.environ.copy()` yields a shallow copy of the environment map;
- `subprocess.run(..., check=True, env=env)` launches one checked subprocess
  event with the supplied argv and env;
- `try/finally` always executes the `finally` body after normal return or
  exception from the `try` body.

## Symbolic Proof

1. Bind connection parameters by the source assignments:

   ```text
   host   = conn_params.get('host', '')
   port   = conn_params.get('port', '')
   dbname = conn_params.get('database', '')
   user   = conn_params.get('user', '')
   passwd = conn_params.get('password', '')
   ```

   This establishes the symbolic variables used by PO-1 and PO-2.

2. Execute argv construction by case analysis on the truthiness of `user`,
   `host`, and `port`.

   - If `user` is truthy, append `['-U', user]`; otherwise append nothing.
   - If `host` is truthy, append `['-h', host]`; otherwise append nothing.
   - If `port` is truthy, append `['-p', str(port)]`; otherwise append nothing.
   - Append `[dbname]` unconditionally.

   The resulting list is exactly the PO-1 expression.

3. Execute environment construction.

   - `env = os.environ.copy()` yields an environment map equal to entry `ENV0`.
   - Case split on `passwd`.
   - If `passwd` is truthy, the assignment `env['PGPASSWORD'] = passwd`
     rewrites the local environment map to `ENV0["PGPASSWORD" <- passwd]`.
   - If `passwd` is falsey, the local environment remains `ENV0`.

   No rewrite touches the global `<environ>` cell after the copy. There is no
   rule or source statement assigning `PGPASSFILE`.

4. Save the original SIGINT handler:

   ```text
   sigint_handler = signal.getsignal(signal.SIGINT)
   ```

   The proof stores this as `SIG0`.

5. Enter the `try` body and execute:

   ```python
   signal.signal(signal.SIGINT, signal.SIG_IGN)
   subprocess.run(args, check=True, env=env)
   ```

   This emits `setSigint("SIG_IGN")` followed by
   `run(args, env, check=True)`, discharging PO-3 and the first half of PO-4.

6. Case split on the subprocess outcome.

   - Normal return: control reaches `finally`.
   - Exception from checked run or launch failure: Python `try/finally`
     transfers through `finally` before propagating the exception.

   In both cases, execute:

   ```python
   signal.signal(signal.SIGINT, sigint_handler)
   ```

   This restores SIGINT to `SIG0`, discharging PO-4.

7. Public compatibility follows from unchanged syntax:

   - `runshell_db(cls, conn_params)` signature is unchanged.
   - `runshell(self)` still delegates to `DatabaseClient.runshell_db()`.
   - `dbshell.Command.handle()` still calls `connection.client.runshell()`.

   This discharges PO-5.

## Adequacy Gate

Intent vs. formal claim:

- `subprocess.run` with custom env and `PGPASSWORD`: pass, from SPEC E1-E3.
- Preserve psql argv from connection parameters: pass, from SPEC E4-E5.
- Remove `.pgpass`/`PGPASSFILE` as the password mechanism: pass, from SPEC E3;
  conflicting public tests are marked SUSPECT in F-2 and PO-6.
- Preserve SIGINT restoration: pass, from SPEC E7.
- Preserve public method/callsite compatibility: pass, from SPEC E8 and PO-5.

No formal-English obligation is stronger than public intent except the explicit
domain assumption PO-8, which is supported by Django's own parameter producer
and public tests.

## Test-Redundancy Recommendation

No tests were run and no test files were modified.

Conditioned on future machine-checking, unit tests that only assert in-domain
argv shape and subprocess env shape would be subsumed by PO-1 through PO-3.
Tests should still be kept for:

- integration with a real `psql` binary;
- external PostgreSQL/libpq handling of `PGPASSWORD`;
- OS signal behavior;
- management command wiring;
- stale legacy `.pgpass` expectations until they are intentionally rewritten
  for the new public contract.

Because this proof is constructed but not machine-checked, FVK does not
recommend deleting any tests now.

## Commands To Machine-Check Later

The benchmark forbids running these commands in this session. They are recorded
for a future environment with K installed:

```sh
kompile fvk/mini-python-dbshell.k --backend haskell
kast --backend haskell fvk/postgresql-client-spec.k
kprove fvk/postgresql-client-spec.k
```

Expected target result for the emitted K sketch files: `kprove` reduces the
claims to `#Top`, modulo the standard-library and external subprocess
boundaries named in PO-7.

## Conclusion

The constructed proof found no source defect in V1. V1 stands unchanged because
it discharges the public-intent obligations and the only contrary public
evidence is the legacy `.pgpass` test expectation that the issue explicitly
supersedes.
