# Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V1 did not fully satisfy the base runner proof obligation PO-RUNSHELL-EMPTY. Keep the PostgreSQL V1 change and add the base runner normalization:

```python
if env:
    env = {**os.environ, **env}
else:
    env = None
```

This directly addresses Finding F1 and preserves non-empty mapping behavior from PO-RUNSHELL-NONEMPTY.

## Recommended Tests For Maintainers

Do not add or edit tests in this task, but a normal Django patch should include:

- PostgreSQL `settings_to_cmd_args_env()` with no env-producing settings returns `None`.
- PostgreSQL `settings_to_cmd_args_env()` with `PASSWORD` still returns `{'PGPASSWORD': ...}`.
- Base `runshell()` with a fake backend returning `{}` calls `subprocess.run(..., env=None, check=True)`.
- Base `runshell()` with a fake backend returning a non-empty env overlays it onto `os.environ`.

## Tests To Keep

- Integration coverage around `dbshell` command dispatch and SIGINT handling.
- Password non-leak coverage for crashing client processes.

## Tests That Are Suspect

- PostgreSQL tests expecting `{}` in the no-password/no-options case encode the reported defect and should be updated rather than used as intent evidence.

## Residual Work

- Machine-check the K artifacts with the recorded `kompile`, `kast`, and `kprove` commands when a K environment is available.
- If maintainers want a stricter public contract, document explicitly that `settings_to_cmd_args_env()` returns `None` when no environment overrides are needed.
