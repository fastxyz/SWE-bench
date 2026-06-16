# Findings

Status: constructed, not machine-checked.

## F-001: Pre-V1 parser omitted `--skip-checks`

- Evidence: `runserver.requires_system_checks = []` prevents `BaseCommand.create_parser()` from adding the common option; the issue asks to add the option to `runserver`.
- Pre-V1 observed vs expected: `manage.py runserver --skip-checks` would be rejected as an unknown option; expected accepted option.
- V1 status: resolved by adding `parser.add_argument('--skip-checks', action='store_true', help='Skip system checks.')` in `runserver.Command.add_arguments()`.
- Proof obligations: PO-001.

## F-002: Pre-V1 `inner_run()` always ran system checks

- Evidence: pre-V1 `inner_run()` unconditionally wrote "Performing system checks..." and called `self.check(display_num_errors=True)`.
- Pre-V1 observed vs expected: even if a `skip_checks` option were passed programmatically, every reload/start path would still run system checks; expected no system checks when `skip_checks=True`.
- V1 status: resolved by guarding the message and `self.check()` with `if not options.get('skip_checks')`.
- Proof obligations: PO-002, PO-003.

## F-003: Migration checks should remain enabled

- Evidence: public intent names system checks; `runserver.py` comments separately explain why migration checks are called in `inner_run()`.
- V1 observed vs expected: `check_migrations()` still runs whether `skip_checks` is true or false; this matches the scoped intent.
- V1 status: confirmed.
- Proof obligations: PO-004.

## F-004: Public in-repo compatibility is preserved

- Evidence: staticfiles `runserver` subclasses core `runserver` and calls `super().add_arguments(parser)`; `testserver` already forwards `skip_checks=True` through `call_command('runserver', ...)`.
- V1 observed vs expected: no method signatures changed; staticfiles inherits the option; programmatic `skip_checks` is now a valid parser destination.
- V1 status: confirmed.
- Proof obligations: PO-005, PO-006.

## F-005: Proof coverage is feature-scoped

- Evidence: the FVK mini semantics models parser/check scheduling only.
- Observed vs expected: the constructed claims do not prove socket serving, autoreload process behavior, settings import behavior, or OS-error handling; expected for a targeted proof of this issue.
- V1 status: residual proof scope note, not a code bug.
- Proof obligations: PO-007.

## Proof-derived findings from `/verify`

- No new code defect was found.
- No proof obligation forced a code change beyond V1.
- The proof remains constructed, not machine-checked; no test removal is recommended until the emitted K commands return `#Top`.
