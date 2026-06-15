# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no new source defect that justifies a V2 edit.

## Trace to findings and obligations

- `F1` identifies the V0 bug: an explicit user batch `U > C` could produce insert batches larger than the backend-compatible cap. `PO2` proves V1 computes `C` in that case, and `PO3` proves emitted batch lengths are capped.
- `F2` checks preservation for `batch_size=None` and `0 < U <= C`. `PO2` shows those cases still use `C` and `U`, respectively, so no compatibility edit is needed.
- `F3` confirms the edit belongs in `_batched_insert()`. `PO5` requires cap calculation after the actual `fields` list is known, which V1 satisfies for both `bulk_create()` insert paths.
- `F4` records the existing lower-bound assumption around `max(ops.bulk_batch_size(...), 1)`. `PO7` keeps the proof domain aligned with existing validation and does not justify changing invalid or unsupported backend behavior.
- `F5` records the compatibility audit. `PO6` confirms no signature, return shape, `ignore_conflicts` branch, returning-row branch, or object state update changed.

## Artifacts

The FVK artifacts are under `fvk/`. The formal core is in `fvk/mini-bulk-create.k` and `fvk/bulk-create-batching-spec.k`; these are constructed but not machine-checked because the task forbids running K tooling.

## Code changes in this phase

No source files under `repo/` were changed during the FVK phase. The existing V1 source edit remains the complete fix.
