# Constructed Proof

Status: constructed, not machine-checked.

## Reproduce the machine check later

These commands were not run in this environment:

```sh
cd fvk
kompile mini-django-management.k --backend haskell
kast --backend haskell runserver-skip-checks-spec.k
kprove runserver-skip-checks-spec.k
```

Expected machine-check result: `#Top` for all three claims.

## Adequacy gate

The intent-only obligations are in `fvk/INTENT_SPEC.md`; the public evidence ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`; the English paraphrase of each K claim is in `fvk/FORMAL_SPEC_ENGLISH.md`; and the claim-by-claim comparison is in `fvk/SPEC_AUDIT.md`.

The adequacy audit passes for the feature scope: the K claims assert exactly that `runserver` gains `--skip-checks`, skips system checks when the option is true, preserves system checks when false, and preserves migration checks in both cases.

## Claim proofs

### RUNSERVER-PARSER-HAS-SKIP-CHECKS

Initial state:

- `<k> createRunserverParser </k>`
- `<parser> .List </parser>`

The mini semantics has one rule for `createRunserverParser`, corresponding to `runserver.Command.add_arguments(parser)`. One rewrite step replaces the empty parser list with the command-specific option list including `argSkipChecks`. By reflexivity on the post-state and framing of `<events>`, the claim reaches the specified postcondition.

This discharges PO-001.

### INNERRUN-NO-SKIP-CHECKS

Initial state:

- `<k> innerRun(false) </k>`
- `<events> .List </events>`

The mini semantics has one rule for the non-skipped branch. It records the existing autoreload exception check, then `eventSystemCheck`, then `eventMigrationCheck`, then `eventServe`. The event sequence matches the claim exactly. No circularity or arithmetic VC is needed.

This discharges PO-002 and the false branch of PO-004.

### INNERRUN-SKIP-CHECKS

Initial state:

- `<k> innerRun(true) </k>`
- `<events> .List </events>`

The mini semantics has one rule for the skipped branch. It records the existing autoreload exception check, omits `eventSystemCheck`, then records `eventMigrationCheck` and `eventServe`. The exact event sequence demonstrates that system checks are skipped while migration checks and server startup remain.

This discharges PO-003 and the true branch of PO-004.

## Source-level proof links

- PO-005 follows from source inspection: `run()` forwards `**options` to `inner_run()` through both `autoreload.run_with_reloader(self.inner_run, **options)` and direct `self.inner_run(None, **options)`.
- PO-006 follows from source inspection: staticfiles calls `super().add_arguments(parser)`, no in-repo subclass adds a duplicate `--skip-checks`, and `call_command()` derives valid keyword options from parser destinations.

## Residual risk

- The proof is constructed but not machine-checked.
- The mini semantics proves parser/check scheduling only; it does not prove socket serving, real autoreload behavior, settings import, or exception handling.
- No tests were run, and no test removal is recommended.

## Test-redundancy recommendation

No existing test is recommended for removal. If the K claims are machine-checked later, tests that assert only these exact parser/check-scheduling points would be redundant in principle, but command integration tests should remain because this feature interacts with argparse, `call_command()`, autoreload, and staticfiles inheritance.
