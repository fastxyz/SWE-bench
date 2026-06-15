# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
static source inspection, and the constructed proof obligations.

## F1: V1 changed command-line `testserver` default behavior

- Classification: code bug in V1.
- Evidence: `testserver.Command.handle()` delegates to `call_command('runserver',
  ...)`. `call_command()` injects `skip_checks=True` when the caller omits the
  option.
- V1 observed path: command-line `testserver` without `--skip-checks` produced no
  `skip_checks` option in `testserver`'s parsed command-line options, then
  delegated to `runserver` without an explicit value. `call_command()` would add
  `skip_checks=True`, and V1 `runserver.inner_run()` would skip `self.check()`.
- Expected path: command-line `testserver` without `--skip-checks` should preserve
  existing command-line behavior and perform the delegated `runserver` system
  check.
- Repair: add `--skip-checks` to `testserver` and pass
  `skip_checks=options.get('skip_checks', False)` to the delegated `runserver`
  call.
- Proof obligations: PO4 and PO5.
- Status: fixed in V2.

## F2: `runserver` is a required explicit-check special case

- Classification: required V1 behavior confirmed.
- Evidence: `runserver.Command` sets `requires_system_checks = False` with the
  comment "Validation is called explicitly each time the server is reloaded" and
  calls `self.check(display_num_errors=True)` in `inner_run()`.
- Observed pre-fix path: adding `--skip-checks` only to automatic
  `BaseCommand.execute()` checks would leave `runserver --skip-checks` unable to
  skip the explicit check.
- Expected path: `runserver --skip-checks` suppresses the explicit system check;
  `runserver` without the flag still checks.
- Repair: V1 added `--skip-checks` in `runserver.add_arguments()` and guarded
  the explicit `self.check()` call with `not options.get('skip_checks')`.
- Proof obligations: PO3.
- Status: V1 change stands.

## F3: Unconditional no-op option is not required by public intent

- Classification: spec ambiguity resolved by source intent.
- Evidence: The issue asks users to skip checks; commands with no automatic or
  explicit system-check path have no checks to skip. Existing Django design also
  uses `requires_system_checks` to decide whether automatic checking applies.
- Alternative considered: add `--skip-checks` to every management command,
  including commands where the flag would be inert.
- Expected path: expose the option on commands whose execution includes a system
  check source, plus explicit-check delegators such as `runserver` and
  `testserver`.
- Proof obligations: PO1, PO3, PO4.
- Status: V2 keeps V1's conditional base parser and adds the missing explicit
  `testserver` case.

## F4: Migration checks must not be skipped by this flag

- Classification: frame condition.
- Evidence: `BaseCommand.execute()` handles `requires_migrations_checks` outside
  the `skip_checks` guard; `runserver` has a separate `check_migrations()` call.
- Expected path: `--skip-checks` skips system checks only. Migration warnings and
  checks remain unaffected.
- Proof obligations: PO7.
- Status: no source change required.

## F5: Machine verification and tests were not run

- Classification: proof-honesty limitation.
- Evidence: The task forbids running tests, Python, or K tooling.
- Expected path: artifacts include exact commands and expected `#Top`, but the
  proof remains constructed, not machine-checked.
- Proof obligations: PO8.
- Status: residual verification step for a future environment.
