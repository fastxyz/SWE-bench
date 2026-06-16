# FVK Notes

## Decision

V1 stands unchanged. No additional source edit is justified by the FVK audit.

## Trace from findings to obligations

F-001 records the original defect: a plain dictionary merge preserved alterable
options that `AlterModelOptions(options={})` was supposed to clear. PO-002 and
PO-003 are the corresponding proof obligations. V1 satisfies them by computing a
merged options map and then removing every key in `operation.ALTER_OPTION_KEYS`
that is absent from `operation.options`.

F-002 covers the empty-options boundary case from the issue. It is discharged by
PO-003 because, when `operation.options` is empty, every alterable key is removed
from the merged options map.

F-003 covers the main risk of over-correcting: accidentally removing unrelated
model options. PO-004 addresses that risk. V1 only iterates over
`ALTER_OPTION_KEYS`, so non-alter options such as `db_table` remain unless
explicitly overridden.

F-004 covers operation-provided overrides. PO-005 and PO-006 address that case.
V1 preserves any key present in `operation.options`, including falsey explicit
values, because the condition is based on key presence rather than value
truthiness.

F-005 is the no-change conclusion. It depends on PO-001 through PO-008: the
reduction shape is unchanged, the option map is equivalent to sequential
`state_forwards()` behavior, non-option `CreateModel` attributes are preserved,
and no public method signature or nonmatching branch behavior changes.

F-006 records the residual process limit. PO-009 requires the proof to remain
labeled constructed, not machine-checked, because this environment forbids
running tests, Python snippets, or K tooling. For that reason I did not recommend
removing tests.

## Source changes during FVK

No source files were changed during the FVK pass. The existing V1 change in
`repo/django/db/migrations/operations/models.py` remains the complete production
fix.

## Artifacts produced

The FVK audit artifacts are:

```text
fvk/SPEC.md
fvk/FINDINGS.md
fvk/PROOF_OBLIGATIONS.md
fvk/PROOF.md
fvk/ITERATION_GUIDANCE.md
```
