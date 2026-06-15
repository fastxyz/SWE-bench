# Baseline Notes

## Root cause

`BaseCommand.execute()` already accepts a `skip_checks` option and uses it to
skip the automatic system check framework call. However, `skip_checks` was only
listed in `base_stealth_options`, so it was accepted for programmatic command
execution but was not added to the command-line argument parser. As a result,
users could not pass `--skip-checks` to normal management commands.

`runserver` has a related special case: it sets `requires_system_checks = False`
because it performs checks explicitly inside `inner_run()` on each reload. A
base parser option tied only to automatic checks would not skip `runserver`'s
manual check call unless `runserver` also exposed and honored the option.

## Changed files

- `repo/django/core/management/base.py`: Added `--skip-checks` to the common
  parser for commands that use automatic system checks. Also added it to the
  help formatter's common-option ordering set so command-specific options still
  appear before common management options in help output.
- `repo/django/core/management/commands/runserver.py`: Added the same
  `--skip-checks` parser option for `runserver` and guarded its explicit
  `self.check()` call with `options.get('skip_checks')`.

## Assumptions and alternatives considered

- I assumed the command-line option should skip Django's pre-command system
  checks, matching the existing `skip_checks` execution option, and should not
  skip migration warnings or checks intentionally run by the `check` command
  itself.
- I considered adding `--skip-checks` unconditionally to every management
  command, but rejected that because commands with `requires_system_checks =
  False` would receive an irrelevant no-op option unless they explicitly run
  checks themselves.
- I treated `runserver` as the one built-in exception that should expose the
  option despite `requires_system_checks = False`, because its manual
  `self.check()` call is the same development-time system check behavior that
  the issue asks users to be able to skip.
