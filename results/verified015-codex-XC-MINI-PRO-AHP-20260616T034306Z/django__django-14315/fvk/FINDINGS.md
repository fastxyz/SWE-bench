# FVK Findings

Status: constructed, not machine-checked.

## F1 - V1 fixed PostgreSQL but left the base empty-map path open

Input:

- A backend `settings_to_cmd_args_env()` returns `(args, {})`.

Observed in V1:

- `BaseDatabaseClient.runshell()` sees `env` as falsey, skips merging with `os.environ`, but still passes `{}` to `subprocess.run(env=...)`.

Expected from public intent:

- The subprocess should inherit the current environment when there are no backend overrides; this is represented by `env=None`.

Classification:

- Code bug in the shared consumer path.

Resolution:

- V2 adds `else: env = None` in `BaseDatabaseClient.runshell()`.

Trace:

- Evidence: E1, E3, E7.
- Proof obligations: PO-RUNSHELL-EMPTY and PO-RUNSHELL-NONE.

## F2 - Visible PostgreSQL tests expecting `{}` are SUSPECT legacy evidence

Input:

- PostgreSQL settings with no `PASSWORD`, no `service`, and no SSL/passfile env options.

Observed in visible public tests:

- `test_nopass` and `test_parameters` expected the env component to be `{}`.

Expected from public issue:

- The env component should be `None`; `{}` is the reported bug because it causes an empty subprocess environment.

Classification:

- Stale public test evidence, not a production-code bug after V2.

Resolution:

- Do not modify tests in this task. Hidden or future fixed tests should assert `None` or assert `runshell()` passes `env=None` for no overrides.

Trace:

- Evidence: E2, E3, E6.
- Proof obligation: PO-PG-NO-OVERRIDES.

## F3 - Non-empty environment override behavior must be preserved

Input:

- PostgreSQL settings with `PASSWORD='secret'`, or options such as `service`, SSL fields, or `passfile`.

Observed risk:

- A fix that blindly returned `None` or dropped the mapping would avoid the empty-env bug but break PostgreSQL client configuration and password handling.

Expected:

- The returned env is non-empty and contains the selected PostgreSQL variables; the base runner overlays it onto `os.environ`.

Classification:

- Frame condition / regression guard.

Resolution:

- PostgreSQL still builds the env dict and returns `env or None`; non-empty dicts are unchanged.
- Base runner still overlays non-empty mappings with `os.environ`.

Trace:

- Evidence: E3, E4, E8.
- Proof obligations: PO-PG-WITH-OVERRIDES and PO-RUNSHELL-NONEMPTY.

## Residual Risks

- The K proof is constructed but not machine-checked.
- The mini-K model abstracts PostgreSQL argument construction as a frame condition rather than proving every argument branch.
- Termination is not separately proved; the audited code slice is straight-line conditionals with no loops.
