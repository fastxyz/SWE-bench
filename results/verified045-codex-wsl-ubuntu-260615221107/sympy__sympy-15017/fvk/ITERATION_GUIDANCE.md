# Iteration Guidance

Status: V1 stands.

## Decision

No V2 source edit is required. The FVK audit confirms that V1 fixes the root cause by changing the constructor-cached `_loop_size` to use the empty-product identity `1` across dense/sparse and mutable/immutable variants.

## Why no source change follows

- F1 identifies the pre-V1 bug and F3 confirms the V1 repair discharges it.
- PO1 proves the scalar rank-0 length behavior.
- PO2 proves nonempty shapes are preserved.
- PO3 connects `__len__` to the constructor-cached value.
- PO4 confirms all storage/mutability variants were covered.
- PO5 finds no compatibility blocker.
- PO6 rejects the stale public test as SUSPECT rather than preserving the bug.

## Recommended follow-up tests

Do not modify tests in this task. For a future test update, add or update coverage for:

- `len(Array(3)) == 1`.
- `len(ImmutableDenseNDimArray(x)) == 1`.
- `len(MutableDenseNDimArray(x)) == 1`.
- Sparse rank-0 scalar length and iteration consistency.
- Preservation of nonempty-shape lengths.

Keep tests for indexing semantics and other array operations, because this proof covers length and cached size only.

## Residual risk

The K proof is constructed, not machine-checked. The mini semantics models the audited size behavior, not full Python or all SymPy array operations. Machine-check the emitted K artifacts before relying on proof-based test removal.
