# FVK Notes

V1 stands unchanged after the FVK audit.

## Decisions

1. Kept the V1 source changes in `repo/xarray/core/common.py` and `repo/xarray/core/variable.py`.
   - Reason: F-001 identifies the pre-V1 bug as the materializing path through `v.data`; PO-001, PO-002, and PO-003 show V1 removes that path for `Variable.chunks`, `Variable.chunksizes`, and `get_chunksizes()`.

2. Did not change `.chunks` to return zarr `encoding["chunks"]` or `encoding["preferred_chunks"]`.
   - Reason: F-002 records that this interpretation conflicts with the public docstrings and tests that distinguish dask chunks from storage/preferred chunks. PO-005 preserves the existing return semantics and error behavior.

3. Did not edit tests or run verification commands.
   - Reason: the task forbids modifying tests and forbids running tests, Python, or K tooling. F-003 records this as an environment/proof-capability limitation, and `fvk/PROOF.md` records the commands for later machine checking.

4. Added FVK artifacts under `fvk/`, including the five requested markdown artifacts plus the constructed abstract K files.
   - Reason: PO-006 requires the spec to be adequate to public intent, and the FVK docs require a formal core. The K files are labeled constructed, not machine-checked.

## Traceability

- F-001 -> PO-001, PO-002, PO-003: confirms the root cause is fixed without more source edits.
- F-002 -> PO-005, PO-006: justifies keeping V1's `.chunks` semantics unchanged.
- F-003 -> `fvk/PROOF.md`: explains why proof commands are present but unexecuted.
- F-004 -> `fvk/ITERATION_GUIDANCE.md`: records useful future tests without modifying the fixed hidden/public test suite.
