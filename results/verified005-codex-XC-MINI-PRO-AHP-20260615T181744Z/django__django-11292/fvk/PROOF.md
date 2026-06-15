# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Claims Proved in the Abstract Model

The mini semantics in `mini-django-management.k` models only the check-skipping
observable. The `<checks>` cell counts system-check invocations.

1. Automatic-check command without skip:
   `run(auto, false)` rewrites to `done` and `<checks>` becomes `N + 1`.
2. Automatic-check command with skip:
   `run(auto, true)` rewrites to `done` and `<checks>` remains `N`.
3. `runserver` without skip:
   `run(runserver, false)` rewrites to `done` and `<checks>` becomes `N + 1`.
4. `runserver` with skip:
   `run(runserver, true)` rewrites to `done` and `<checks>` remains `N`.
5. `testserver` without skip:
   `run(testserver, false)` rewrites through `delegateRunserver(false)` to
   `run(runserver, false)`, then to `done` with `<checks> = N + 1`.
6. `testserver` with skip:
   `run(testserver, true)` rewrites through `delegateRunserver(true)` to
   `run(runserver, true)`, then to `done` with `<checks> = N`.
7. No-check command:
   `run(nocheck, S)` rewrites to `done` with `<checks> = N`.

## Symbolic Proof Sketch

The proof has no loops or recursion in the reduced model, so no circularity is
needed. Each claim discharges by symbolic execution and transitivity over the
rewrite rules:

- Automatic-check claims apply one of the two `run(auto, Skip)` rules.
- `runserver` claims apply one of the two `run(runserver, Skip)` rules.
- `testserver` claims apply the delegation rule, then the
  `delegateRunserver(S)` rule, then the matching `run(runserver, S)` rule.
- The no-check claim applies the `run(nocheck, S)` rule.

Arithmetic obligations are limited to preserving `N` or rewriting `N` to
`N +Int 1`, so no nonlinear simplification lemmas are required.

## Mapping Proof to Source

- PO1 and PO2 map to `BaseCommand.create_parser()` and
  `BaseCommand.execute()` in `repo/django/core/management/base.py`.
- PO3 maps to `runserver.Command.add_arguments()` and
  `runserver.Command.inner_run()` in
  `repo/django/core/management/commands/runserver.py`.
- PO4 maps to `testserver.Command.add_arguments()` and
  `testserver.Command.handle()` in
  `repo/django/core/management/commands/testserver.py`.
- PO5 maps to unchanged `call_command()` behavior in
  `repo/django/core/management/__init__.py`.
- PO6 maps to `DjangoHelpFormatter.show_last`.
- PO7 maps to the unchanged migration-check paths in `BaseCommand.execute()` and
  `runserver.inner_run()`.

## Proof-Derived Finding

The V1 proof attempt for `testserver` failed the claim
`run(testserver, false) => <checks> N + 1`. The source delegation did not pass a
false skip value, so the delegated programmatic `call_command('runserver')` path
injected `skip_checks=True`. This is Finding F1 and is repaired in V2 by
explicit propagation.

## Machine-Check Commands

These commands were not run in this workspace:

```sh
cd fvk
kompile mini-django-management.k --backend haskell
kast --backend haskell management-skip-checks-spec.k
kprove management-skip-checks-spec.k
```

Expected result after machine checking: `#Top`.

## Test Guidance

No tests were modified. Because the proof is constructed but not
machine-checked, no test should be removed. Useful tests for a future executable
environment would cover:

- a command with `requires_system_checks=True` runs checks by default and skips
  with `--skip-checks`;
- `runserver` runs explicit checks by default and skips with `--skip-checks`;
- command-line `testserver` delegates `skip_checks=False` by default;
- command-line `testserver --skip-checks` delegates `skip_checks=True`;
- programmatic `call_command('testserver')` still delegates `skip_checks=True`.
