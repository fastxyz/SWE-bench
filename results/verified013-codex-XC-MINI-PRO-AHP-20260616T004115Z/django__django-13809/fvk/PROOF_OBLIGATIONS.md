# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Parser availability

- Claim: `runserver` parser construction includes `argSkipChecks`.
- Source evidence: E1, E2, E4.
- Code evidence: `repo/django/core/management/commands/runserver.py` adds `--skip-checks` in `add_arguments()`.
- Finding trace: F-001.

## PO-002: Default system-check preservation

- Claim: with `skip_checks=False`, `inner_run()` emits `eventSystemCheck`.
- Source evidence: E2, E3, E4.
- Code evidence: `if not options.get('skip_checks'):` enters the block when the parser default is false or the option is omitted in direct calls.
- Finding trace: F-002.

## PO-003: Skipped system-check behavior

- Claim: with `skip_checks=True`, `inner_run()` does not emit `eventSystemCheck`.
- Source evidence: E1, E3.
- Code evidence: `if not options.get('skip_checks'):` bypasses the block when the option is true.
- Finding trace: F-002.

## PO-004: Migration checks preserved

- Claim: both `innerRun(false)` and `innerRun(true)` emit `eventMigrationCheck`.
- Source evidence: E6.
- Code evidence: `self.check_migrations()` remains outside and after the guarded system-check block.
- Finding trace: F-003.

## PO-005: Option propagation through run modes

- Claim: the same `options` dictionary reaches `inner_run()` with and without autoreload.
- Source evidence: E3, E4.
- Code evidence: `run()` calls `autoreload.run_with_reloader(self.inner_run, **options)` when reloading and `self.inner_run(None, **options)` otherwise.
- Finding trace: F-002.

## PO-006: Public compatibility

- Claim: V1 does not break in-repo subclasses or programmatic call paths.
- Source evidence: E7, E8.
- Code evidence: no signatures changed; staticfiles calls `super().add_arguments(parser)`; `call_command()` validates parser destinations and defaults missing `skip_checks` to true.
- Finding trace: F-004.

## PO-007: Proof scope honesty

- Claim: constructed proof only covers the issue-relevant feature slice.
- Evidence: FVK mini semantics abstracts network/autoreload/runtime failure behavior away.
- Finding trace: F-005.
