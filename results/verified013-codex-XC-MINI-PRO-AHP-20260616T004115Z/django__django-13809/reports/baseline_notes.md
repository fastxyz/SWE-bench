# Baseline Notes

## Root cause

`runserver` sets `requires_system_checks = []` because it performs system checks manually inside `inner_run()` after autoreload starts. That prevents `BaseCommand.create_parser()` from adding the common `--skip-checks` option, and the manual `self.check(display_num_errors=True)` call always runs on every reload with no option-based guard.

## Files changed

- `repo/django/core/management/commands/runserver.py`
  - Added a `--skip-checks` parser option directly to `runserver`, using the same help text and `store_true` behavior as other management commands.
  - Wrapped the explicit `self.check(display_num_errors=True)` call and its "Performing system checks..." output in `if not options.get('skip_checks'):` so command-line and programmatic callers can skip system checks.

## Assumptions

- The option should skip only Django system checks, matching the existing meaning of `--skip-checks` on other management commands.
- The migration warning check in `runserver` should still run because it is a separate `check_migrations()` path, not part of the system check framework.
- `options.get('skip_checks')` is used instead of indexing `options['skip_checks']` so direct internal calls to `inner_run()` without parser defaults remain compatible.

## Alternatives considered

- Changing `requires_system_checks` to `__all__` was rejected because `runserver` intentionally performs checks inside `inner_run()` after autoreload setup. Moving checks back to `BaseCommand.execute()` would change reload-time behavior.
- Adding a broader skip that also suppresses `check_migrations()` was rejected because the requested option is specifically named and documented for system checks, while migration checks are controlled separately in Django's command infrastructure.
