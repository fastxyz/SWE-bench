# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no unresolved finding that requires another production-code edit.

## Trace from findings and proof obligations

- `F-001` identifies the pre-V1 bug: an existing `IndexVariable` can be returned by `to_index_variable()` as `self`, so assigning `.dims` mutates the input dataset's variable. `PO-001` and `PO-002` require a no-mutation frame condition and alias isolation. V1 satisfies both by calling `.copy(deep=False)` before assigning `.dims`.
- `F-002` generalizes the aliasing issue: callers cannot assume `to_index_variable()` transfers ownership. `PO-002` requires ownership before metadata mutation. V1 supplies that ownership in the promoted branch.
- `PO-003` requires the returned promoted variable to still receive rewritten dimensions. V1 preserves this because the assignment to `var.dims` remains in place, but now targets the copied result variable.
- `PO-004` confirms the non-promoted branch already used `to_base_variable()`, which constructs a fresh `Variable`, so no source change was needed there.
- `PO-005` and `PO-006` confirm the fix leaves validation, signature, return shape, and public call compatibility unchanged.
- `F-003` notes a possible micro-optimization to copy only when `to_index_variable()` returns the original object. I rejected that as a V2 change because no public-intent or proof obligation requires it; it would only narrow an internal shallow metadata copy.
- `F-004` and `PO-007` record that the proof is constructed, not machine-checked. This affects test-removal confidence only; it does not require a code change.

## Artifacts

The required FVK files are present:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Supporting adequacy and formal-core files are also present:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python-swapdims.k`
- `fvk/swap-dims-spec.k`

## Execution

No tests, Python code, `kompile`, `kast`, or `kprove` were run, per the task constraints. The K commands are written into the FVK artifacts for later use in an environment where execution is allowed.
