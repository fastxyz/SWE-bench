# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no source-level defect that required a V2 code edit.

## Trace to findings and proof obligations

- Kept the `--skip-checks` parser addition in `runserver.Command.add_arguments()`.
  - Finding trace: `fvk/FINDINGS.md` F-001.
  - Proof trace: `fvk/PROOF_OBLIGATIONS.md` PO-001.
  - Reason: the public issue directly requires the option, and `runserver` cannot receive the base parser option because `requires_system_checks = []`.

- Kept the `if not options.get('skip_checks'):` guard around the explicit system-check message and `self.check(display_num_errors=True)`.
  - Finding trace: `fvk/FINDINGS.md` F-002.
  - Proof trace: `fvk/PROOF_OBLIGATIONS.md` PO-002 and PO-003.
  - Reason: this is the feature's operative behavior. It preserves checks when the option is false and skips them when true.

- Kept `self.check_migrations()` outside the skip guard.
  - Finding trace: `fvk/FINDINGS.md` F-003.
  - Proof trace: `fvk/PROOF_OBLIGATIONS.md` PO-004.
  - Reason: the requested flag is scoped to system checks. Migration checks are a separate runserver behavior and the source comment already treats them separately.

- Made no compatibility edits.
  - Finding trace: `fvk/FINDINGS.md` F-004.
  - Proof trace: `fvk/PROOF_OBLIGATIONS.md` PO-005 and PO-006.
  - Reason: no method signatures changed; options are forwarded through both reloader paths; the in-repo staticfiles subclass inherits the option through `super()`; programmatic `skip_checks` is now a parser-recognized option.

- Did not broaden the proof into full `runserver` networking or autoreload process semantics.
  - Finding trace: `fvk/FINDINGS.md` F-005.
  - Proof trace: `fvk/PROOF_OBLIGATIONS.md` PO-007.
  - Reason: V1 only changes parser/check scheduling. The FVK artifacts state this scope explicitly and label the proof constructed, not machine-checked.

## No execution

No tests, Python, or K tooling were run. The K commands are recorded in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md` for a future environment that has K installed.
