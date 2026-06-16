# FVK Spec

Status: constructed, not machine-checked.

## Target

Audit V1 for `django__django-13809`: `repo/django/core/management/commands/runserver.py` adds `--skip-checks` and skips the explicit system-check call when requested.

The formal model covers the behavior changed by V1:

- parser construction for the core `runserver` command;
- the check scheduling prefix of `Command.inner_run()` after `autoreload.raise_last_exception()`;
- preservation of migration checks and server start after that prefix.

It intentionally does not model socket serving, network errors, keyboard interrupts, settings import, or the real autoreloader process. Those behaviors are unchanged by V1 and remain residual risk outside this feature proof.

## Public Intent Ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical obligations:

- E1: `runserver` must accept `--skip-checks`.
- E2: the option must match existing management-command skip-check behavior.
- E3: skipped checks must avoid the reload/start `self.check()` call.
- E4: `runserver` performs validation manually after reload setup, so the option must be wired locally.
- E6: migration checks are separate and stay enabled.
- E7/E8: public in-repo subclass and programmatic call paths must remain compatible.

## Domain

Inputs in scope:

- `skip_checks` is a boolean option supplied by argparse or by `call_command` defaults.
- `runserver.add_arguments(parser)` is called with a normal management-command parser.
- `inner_run()` reaches the check-scheduling region, meaning `autoreload.raise_last_exception()` did not raise.

Inputs out of scope:

- malformed parser objects;
- exceptions before the check-scheduling region;
- socket/runtime server failures after check scheduling;
- external user subclasses not present in this repository.

## Observable Events

The mini semantics records two observables:

- parser options: whether `argSkipChecks` is present in the runserver parser option list;
- inner-run events: `eventSystemCheck`, `eventMigrationCheck`, and `eventServe`.

## Formal Claims

Formal K files:

- `fvk/mini-django-management.k`
- `fvk/runserver-skip-checks-spec.k`

Claim summaries:

1. `RUNSERVER-PARSER-HAS-SKIP-CHECKS`
   - Starting from `createRunserverParser`, the resulting parser contains `argSkipChecks` together with the existing runserver options.
   - Provenance: E1, E2, E4.

2. `INNERRUN-NO-SKIP-CHECKS`
   - Starting from `innerRun(false)`, events are `eventRaiseLastException`, `eventSystemCheck`, `eventMigrationCheck`, `eventServe`.
   - Provenance: E3, E4, E6.

3. `INNERRUN-SKIP-CHECKS`
   - Starting from `innerRun(true)`, events are `eventRaiseLastException`, `eventMigrationCheck`, `eventServe`; no `eventSystemCheck` occurs.
   - Provenance: E1, E3, E6.

## Adequacy

The formal English paraphrase in `fvk/FORMAL_SPEC_ENGLISH.md` matches the intent in `fvk/INTENT_SPEC.md`; see `fvk/SPEC_AUDIT.md`. The proof is only a constructed feature proof and must not be represented as machine-checked until the commands in `fvk/PROOF.md` return `#Top`.
