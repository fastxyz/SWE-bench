# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public surface

- `django.core.management.commands.runserver.Command.add_arguments(parser)` now adds `--skip-checks`.
- `django.core.management.commands.runserver.Command.inner_run(*args, **options)` now reads `options.get('skip_checks')`.

## Signature compatibility

- No Python function or method signature changed.
- `inner_run()` uses `options.get('skip_checks')`, so direct internal callers that omit the key keep the old behavior of running system checks.

## Parser compatibility

- `BaseCommand.create_parser()` does not add `--skip-checks` for `runserver` because `runserver.requires_system_checks = []`.
- Adding the option in `runserver.add_arguments()` therefore does not duplicate a base option for the in-repo command.

## In-repo subclass compatibility

- `django.contrib.staticfiles.management.commands.runserver.Command` calls `super().add_arguments(parser)` and then adds staticfiles-specific options.
- It inherits `--skip-checks` without a code change.
- It does not add an option with the same spelling or destination.

## Programmatic call compatibility

- `django.core.management.call_command()` validates keyword options against parser destinations.
- With V1, `skip_checks` is a parser destination for `runserver`, so `call_command('runserver', skip_checks=True)` is valid.
- If `skip_checks` is omitted, `call_command()` sets it to true by default, which matches existing management-command behavior and existing public test expectations for `testserver` forwarding.

## Residual compatibility note

External subclasses outside this repository that both inherit core `runserver` and manually add their own `--skip-checks` option could see an argparse duplicate-option conflict. No such subclass exists in the allowed in-repo evidence. This is not a blocker for V1 because the new option is the requested public API addition and the in-repo virtual dispatch path is compatible.
