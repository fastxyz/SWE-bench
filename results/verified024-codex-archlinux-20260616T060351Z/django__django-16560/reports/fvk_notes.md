# FVK Notes

The FVK audit confirms V1 as the V2 source fix. No additional source edits were
made after the audit.

## Decision log

D-1. Keep `violation_error_code` on `BaseConstraint` with default `None`.

- Trace: F-001, F-002, F-004; PO-1, PO-2, PO-3.
- Reason: public intent requires a customizable code, and default omission must
  preserve old behavior.

D-2. Keep deconstruction and clone preservation.

- Trace: F-002; PO-3.
- Reason: constraints are serialized into migrations via `deconstruct()`, and
  `clone()` reconstructs from that result. Without the kwarg, custom codes would
  be lost outside direct construction.

D-3. Keep code propagation in `CheckConstraint.validate()`.

- Trace: F-001; PO-4.
- Reason: this validation path raises directly with
  `get_violation_error_message()`, so it is in scope for the new custom code.

D-4. Keep code propagation in expression and conditional
`UniqueConstraint.validate()` paths.

- Trace: F-001; PO-5.
- Reason: these paths also raise with `get_violation_error_message()`, so the
  stored code must be passed to `ValidationError`.

D-5. Keep field-only `UniqueConstraint` without condition unchanged.

- Trace: F-003; PO-5.
- Reason: public Django docs state that `violation_error_message` is not used for
  this branch and that it shows the same message as `Field.unique` or
  `unique_together`. The audit treats `violation_error_code` as following that
  documented exception.

D-6. Keep code propagation in PostgreSQL `ExclusionConstraint.validate()`.

- Trace: F-001; PO-6.
- Reason: `ExclusionConstraint` is a concrete `BaseConstraint` subclass with its
  own constructor and validation raises, so it must accept and apply the same
  stored code.

D-7. Keep equality and `repr()` handling for `violation_error_code`.

- Trace: PO-7.
- Reason: Django already includes `violation_error_message` in these developer
  observables. Treating two constraints with different custom codes as equal
  would lose a public behavioral distinction.

D-8. Do not change tests or run commands.

- Trace: task restrictions; PROOF residual risk.
- Reason: tests, Python, Django, and K tooling execution are forbidden in this
  environment. The proof is constructed, not machine-checked.

D-9. Do not update docs in this phase.

- Trace: F-005.
- Reason: docs are stale relative to the new API and should be updated in a full
  contribution, but the benchmark task is a source-code repair with fixed hidden
  tests. The code correctness obligations are discharged without a docs edit.

