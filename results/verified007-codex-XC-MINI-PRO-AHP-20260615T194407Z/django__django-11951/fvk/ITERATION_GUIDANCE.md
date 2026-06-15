# Iteration Guidance

Constructed, not machine-checked.

## Code decision

V1 stands unchanged. The FVK audit found the original V0 bug and confirmed that V1 discharges the relevant obligations:

- F1 is resolved by PO2 and PO3.
- F2 shows the unchanged cases are preserved.
- F3 confirms the cap calculation is placed in `_batched_insert()`, where the actual field list is available.
- F5 confirms no public compatibility issue was introduced.

No V2 source edit is justified by the FVK findings.

## Suggested tests for a later test-authoring pass

Do not edit tests in this task. If tests are added later, useful public tests would cover:

- Explicit `batch_size` larger than the SQLite-compatible cap, expecting multiple smaller insert batches.
- Explicit `batch_size` smaller than the cap, expecting the smaller user batch to be preserved.
- `batch_size=None`, expecting backend-compatible batching.
- Both `bulk_create()` object partitions: objects with explicit primary keys and objects without `AutoField`.
- The `ignore_conflicts=True` path, confirming the same cap applies without changing conflict handling.

## Machine verification follow-up

When an execution environment is available, run the commands in `fvk/PROOF.md`. Keep any existing tests until the K proof is machine-checked and the real Django test suite passes.
