# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Parser exposure for automatic-check commands

For any command instance with `requires_system_checks == True`,
`BaseCommand.create_parser()` must add an argparse option whose long spelling is
`--skip-checks`, whose destination is `skip_checks`, and whose true value is
passed through `run_from_argv()` to `execute()`.

Discharge: `repo/django/core/management/base.py` adds the argument under
`if self.requires_system_checks:`. `argparse`'s `store_true` action gives
`False` when omitted and `True` when present.

Related findings: F3.

## PO2: Automatic checks honor the parsed flag

For automatic-check commands, `BaseCommand.execute()` must call `self.check()`
iff `requires_system_checks` is true and `skip_checks` is false.

Discharge: the existing guard remains
`if self.requires_system_checks and not options.get('skip_checks'):`. The V2
parser supplies the option for command-line execution, and `call_command()`
continues to supply it for programmatic execution.

Related findings: F3.

## PO3: `runserver` exposes and honors the flag for explicit checks

`runserver` must expose `--skip-checks` even though it has
`requires_system_checks = False`, and `inner_run()` must call
`self.check(display_num_errors=True)` iff the option is false.

Discharge: `repo/django/core/management/commands/runserver.py` adds the parser
argument and wraps the explicit check in `if not options.get('skip_checks'):`.

Related findings: F2.

## PO4: `testserver` preserves command-line default and propagates explicit skip

Command-line `testserver` without `--skip-checks` must delegate to `runserver`
with `skip_checks=False`; command-line `testserver --skip-checks` must delegate
with `skip_checks=True`; programmatic `call_command('testserver')` must preserve
the existing `call_command()` default of `skip_checks=True`.

Discharge: `repo/django/core/management/commands/testserver.py` adds a
`store_true` parser argument and calls delegated `runserver` with
`skip_checks=options.get('skip_checks', False)`. For command-line execution,
argparse supplies `False` or `True`; for direct execution that omits the key,
the default is `False`; for programmatic `call_command('testserver')`,
`call_command()` supplies `skip_checks=True`.

Related findings: F1.

## PO5: Programmatic `call_command()` compatibility is preserved

`call_command()` must keep accepting `skip_checks` and must keep the historical
default: omitted means true, explicit false means checks run.

Discharge: `repo/django/core/management/__init__.py` is unchanged. The existing
`base_stealth_options` still includes `skip_checks`, and the existing
`if 'skip_checks' not in options: defaults['skip_checks'] = True` behavior
stands.

Related findings: F1.

## PO6: Help ordering remains consistent

`--skip-checks` is a common management option and should appear with the other
common options after command-specific options in help output.

Discharge: `DjangoHelpFormatter.show_last` now includes `--skip-checks`.

Related findings: none.

## PO7: Migration checks are unaffected

The new flag must not suppress `requires_migrations_checks` or
`runserver.check_migrations()`.

Discharge: V2 does not move or guard either migration-check path with
`skip_checks`; only system-check calls are guarded.

Related findings: F4.

## PO8: FVK proof honesty

The artifacts must state that no K/Python/test execution happened and must
include exact commands for later machine checking.

Discharge: `fvk/SPEC.md` and `fvk/PROOF.md` include the commands and label the
proof "constructed, not machine-checked."

Related findings: F5.
