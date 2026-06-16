# Intent Specification

Status: constructed, not machine-checked.

## Public intent

1. `runserver` must accept a `--skip-checks` command-line option.
   - Source: `benchmark/PROBLEM.md`, "Add --skip-checks option to the runserver command."
   - Obligation: parser construction for `runserver` includes an option whose destination is `skip_checks` and whose command-line spelling is `--skip-checks`.

2. The option must behave consistently with management commands that perform system checks.
   - Source: `benchmark/PROBLEM.md`, "It would be consistent with other management commands performing system checks."
   - Obligation: `--skip-checks` uses `store_true` boolean behavior and the help text "Skip system checks.", matching the existing command framework and `migrate`.

3. When `--skip-checks` is supplied, `runserver` must not run Django system checks during the runserver reload/start path.
   - Source: `benchmark/PROBLEM.md`, "rather have checks enabled exclusively in CI/CD than wait 15-20 seconds for each project reload during development."
   - Obligation: the explicit `self.check(display_num_errors=True)` call in `inner_run()` is skipped when `skip_checks` is true.

4. When `--skip-checks` is not supplied, existing `runserver` system-check behavior must be preserved.
   - Source: the option is a skip flag, not a default behavior change.
   - Obligation: `inner_run(skip_checks=False)` still writes the "Performing system checks..." message and invokes `self.check(display_num_errors=True)`.

5. Migration warnings are outside the `--skip-checks` obligation.
   - Source: option name and existing Django wording "system checks"; source comment in `runserver.py`, "Need to check migrations here, so can't use the requires_migrations_check attribute."
   - Obligation: `check_migrations()` remains on both skipped and non-skipped paths.

6. Existing public `runserver` subclass behavior must remain compatible.
   - Source: in-repo subclass `django.contrib.staticfiles.management.commands.runserver.Command` calls `super().add_arguments(parser)`.
   - Obligation: the staticfiles command inherits the new option without requiring a signature or override change.

## Out of scope for this FVK pass

- Full network serving behavior, socket errors, keyboard interrupts, real autoreload process management, and Django settings import behavior are not changed by V1 and are not modeled in the mini semantics.
- The proof is a partial feature proof for parser/check scheduling, not a whole-program proof of `runserver`.
