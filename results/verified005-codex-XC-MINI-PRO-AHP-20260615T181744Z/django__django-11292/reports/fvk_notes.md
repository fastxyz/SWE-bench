# FVK Notes

## Decisions and Traceability

1. Changed `repo/django/core/management/commands/testserver.py`.
   - Reason: `fvk/FINDINGS.md` F1 showed V1 changed command-line
     `testserver` behavior. Because `testserver` delegates through
     `call_command('runserver')`, V1 allowed `call_command()` to inject its
     programmatic default `skip_checks=True`, so command-line `testserver`
     without `--skip-checks` would skip checks.
   - Obligation: `fvk/PROOF_OBLIGATIONS.md` PO4 requires command-line
     `testserver` without the flag to delegate `skip_checks=False`, with the
     flag to delegate `True`, and programmatic `call_command('testserver')` to
     preserve the existing default `True`.
   - Implementation: added `--skip-checks` to `testserver.add_arguments()` and
     passed `skip_checks=options.get('skip_checks', False)` to the internal
     `runserver` call.

2. Kept the V1 `BaseCommand` change.
   - Reason: `fvk/FINDINGS.md` F3 resolves the scope: the issue requires a
     visible way to skip checks where command execution has a system-check path,
     not a no-op option on commands with no checks.
   - Obligations: PO1 requires parser exposure for automatic-check commands;
     PO2 requires the existing `execute()` check gate to honor the parsed flag;
     PO6 requires help ordering to treat `--skip-checks` as a common option.
   - Implementation: V1 already added the option under
     `if self.requires_system_checks:` and added it to
     `DjangoHelpFormatter.show_last`, so no further source edit was needed.

3. Kept the V1 `runserver` change.
   - Reason: `fvk/FINDINGS.md` F2 identifies `runserver` as the required
     explicit-check special case because it disables automatic checks and calls
     `self.check()` inside `inner_run()`.
   - Obligation: PO3 requires `runserver` to expose `--skip-checks` and guard
     the explicit check with that option.
   - Implementation: V1 already added the parser argument and guarded
     `self.check(display_num_errors=True)` with
     `if not options.get('skip_checks'):`; that stands.

4. Kept `call_command()` unchanged.
   - Reason: `fvk/FINDINGS.md` F1 depends on preserving the distinction between
     command-line defaults and programmatic defaults; changing `call_command()`
     would solve the symptom by altering a broader public API.
   - Obligation: PO5 requires the historical programmatic default to remain:
     omitted `skip_checks` means `True`, explicit `False` means checks run.
   - Implementation: no edit to `repo/django/core/management/__init__.py`.

5. Kept migration-check behavior unchanged.
   - Reason: `fvk/FINDINGS.md` F4 treats migration checks as a frame condition.
     The public issue says system checks, and Django has a separate migration
     warning path.
   - Obligation: PO7 requires `--skip-checks` not to suppress migration checks.
   - Implementation: no guard was added around `BaseCommand.check_migrations()`
     or `runserver.check_migrations()`.

6. Did not run tests or tooling.
   - Reason: the task forbids tests, Python execution, and K tooling.
   - Obligation: PO8 requires the FVK artifacts to label the proof as
     constructed, not machine-checked, and to include exact future commands.
   - Implementation: `fvk/SPEC.md` and `fvk/PROOF.md` include the commands and
     the honesty caveat.

## Result

V2 differs from V1 only where the FVK audit found a concrete defect:
`testserver` now exposes and propagates the skip decision. The V1 base and
`runserver` changes remain justified by the public intent and constructed proof
obligations.
