# FVK Specification

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

This audit covers the management-command behavior affected by the issue:

- `BaseCommand.create_parser()` exposes command-line options.
- `BaseCommand.execute()` runs automatic system checks.
- `runserver.Command.inner_run()` runs explicit system checks because
  `runserver` sets `requires_system_checks = False`.
- `testserver.Command.handle()` delegates to `runserver` with `call_command()`.
- `call_command()` keeps its documented programmatic default of
  `skip_checks=True` when the caller omits the option.

The model intentionally abstracts away unrelated command work, settings setup,
fixture loading, server sockets, migrations warnings, color handling, and error
formatting. Those are outside the issue's observable check-skipping contract.

## Public Intent Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | `benchmark/PROBLEM.md` | "Add --skip-checks option to management commands." | Commands whose execution includes system checks must have a visible command-line flag for skipping those checks. | Encoded in PO1, PO3, PO4. |
| I2 | `benchmark/PROBLEM.md` | "Management commands already have skip_checks stealth option." | The visible flag should use the existing `skip_checks` execution option, not a new parallel mechanism. | Encoded in PO2, PO3, PO4, PO5. |
| I3 | `benchmark/PROBLEM.md` | "allow users to skip checks when running a command from the command line" | With `--skip-checks`, system checks do not run; without it, existing command-line check behavior is preserved. | Encoded in PO2, PO3, PO4. |
| I4 | Source comment in `runserver.py` | "Validation is called explicitly each time the server is reloaded." | `runserver` must be treated as an explicit-check special case even though `requires_system_checks = False`. | Encoded in PO3. |
| I5 | Source code in `call_command()` | `if 'skip_checks' not in options: defaults['skip_checks'] = True` | Programmatic `call_command()` default remains skip-by-default unless an explicit `skip_checks` is supplied. | Encoded in PO5 and compatibility audit. |
| I6 | Source code in `testserver.py` | `testserver` calls `call_command('runserver', ...)` | `testserver` must pass the command-line skip decision through to `runserver`; otherwise `call_command()`'s default changes CLI behavior. | Finding F1; fixed in V2; encoded in PO4. |
| I7 | `BaseCommand.execute()` source | `requires_migrations_checks` is separate from `requires_system_checks` | `--skip-checks` skips system checks only; migration warnings remain unaffected. | Encoded in PO7. |

## Intent-Only Spec

1. For a command whose `BaseCommand.execute()` automatic check gate applies,
   command-line parsing accepts `--skip-checks`.
2. For such a command, command-line execution without `--skip-checks` performs
   the automatic system check exactly as before; command-line execution with
   `--skip-checks` suppresses that automatic system check.
3. `runserver` accepts `--skip-checks` even though its automatic gate is disabled,
   because it runs `self.check()` explicitly inside `inner_run()`.
4. `runserver` without `--skip-checks` still performs its explicit system check;
   `runserver --skip-checks` suppresses only that explicit system check.
5. `testserver` accepts `--skip-checks` and propagates the caller's skip decision
   to the delegated `runserver` command. Command-line `testserver` without the
   flag must not inherit `call_command()`'s programmatic skip-by-default behavior.
6. Programmatic `call_command()` keeps accepting `skip_checks` as a stealth/common
   option and keeps its historical default: omitted means `True`, explicit
   `False` means run checks where the target command honors them.
7. Commands with no automatic or explicit system-check path do not need a visible
   no-op `--skip-checks` option.
8. Command-specific help ordering remains stable: command-specific options appear
   before common management options, including `--skip-checks`.

## Formal Model

The formal core is in:

- `fvk/mini-django-management.k`
- `fvk/management-skip-checks-spec.k`

The mini semantics models commands as `run(command, skipFlag)` and counts system
check invocations in a `<checks>` cell. The relevant claims are:

- `run(auto, false)` increments `<checks>` by one.
- `run(auto, true)` leaves `<checks>` unchanged.
- `run(runserver, false)` increments `<checks>` by one.
- `run(runserver, true)` leaves `<checks>` unchanged.
- `run(testserver, false)` delegates to `runserver` with `false` and increments
  `<checks>` by one.
- `run(testserver, true)` delegates to `runserver` with `true` and leaves
  `<checks>` unchanged.
- `run(nocheck, S)` leaves `<checks>` unchanged.

Exact commands to machine-check later, not executed here:

```sh
cd fvk
kompile mini-django-management.k --backend haskell
kast --backend haskell management-skip-checks-spec.k
kprove management-skip-checks-spec.k
```

Expected machine-check result after installing/running K: `#Top`.

## Formal Spec English

- The automatic-check command claim says: for all initial check counts `N`,
  running an automatic-check command without the skip flag terminates with
  `N + 1` checks; running it with the skip flag terminates with `N` checks.
- The `runserver` claim says: for all `N`, its explicit reload-time system check
  runs exactly when the skip flag is false.
- The `testserver` claim says: for all `N`, `testserver` preserves the caller's
  skip decision when it delegates to `runserver`; false means one check, true
  means no check.
- The no-check command claim says: commands with no system-check path have no
  check-count effect in this issue slice.

## Adequacy Audit

All formal claims pass the intent round trip:

- I1/I2/I3 are covered by the automatic and runserver claims.
- I4 is covered by the explicit `runserver` claims.
- I5 is preserved by leaving `call_command()` unchanged and by modeling explicit
  delegation rather than changing programmatic defaults.
- I6 is covered by the repaired `testserver` claims.
- I7 is intentionally outside the `<checks>` model because migration checks are a
  separate observable and are not skipped by the code.
- I8 is covered as a proof obligation over `DjangoHelpFormatter.show_last`.

## Public Compatibility Audit

- `BaseCommand.create_parser()` signature is unchanged. The parser gains a common
  option only for commands that use automatic system checks.
- `BaseCommand.execute()` signature and `call_command()` signature are unchanged.
- `runserver.Command.add_arguments()` gains `--skip-checks`; the staticfiles
  subclass calls `super().add_arguments(parser)`, so it inherits the option.
- `runserver.Command.inner_run()` signature is unchanged and reads
  `options.get('skip_checks')`, preserving direct callers that omit the option.
- `testserver.Command.add_arguments()` gains `--skip-checks`.
- `testserver.Command.handle()` still accepts `**options`; it now passes
  `skip_checks=options.get('skip_checks', False)` to `runserver`, preserving
  programmatic `call_command('testserver')` behavior because `call_command()`
  supplies `skip_checks=True` when omitted.
- No public test files were modified.
