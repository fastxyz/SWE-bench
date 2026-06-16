# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V1 should be improved, not left exactly unchanged. The audit found F2: V1
normalized scalar zero but left matrix-zero placeholders untouched. V2 keeps the
same localized repair but changes the zero-normalization guard to rebuild both
`is_ZeroMatrix` entries and scalar zero entries as shaped `ZeroMatrix` blocks.

No broader source changes are recommended. F3 and PO-7 support keeping the
repair localized to `BlockMatrix._blockmul`.

## Suggested Tests For A Normal Development Environment

Do not add or edit tests in this benchmark. In a normal environment, add or keep
coverage for:

- `BlockMatrix([[a, z], [z, z]])._blockmul(b)._blockmul(b)` does not raise.
- `block_collapse(b * b * b)` does not raise and has zero blocks with usable
  block dimensions.
- A rectangular aligned block product with zero result entries stores
  `ZeroMatrix(row_block_size, col_block_size)`.
- Non-zero block product entries are preserved.

## Test Redundancy

No test removal is recommended in this session. The proof is not
machine-checked, and the benchmark forbids test execution and test edits. After
`kprove` returns `#Top` in a proper environment, point tests that only restate
the in-domain normalized-zero contract may be considered redundant, but
integration and regression tests should be kept unless a maintainer explicitly
chooses otherwise.

## Next Verification Step

Run the recorded K commands only in an environment where K is available and
execution is permitted:

```sh
cd fvk
kompile mini-blockmatrix.k --backend haskell
kast --backend haskell blockmatrix-spec.k
kprove blockmatrix-spec.k
```

Until then, treat the FVK proof as a constructed proof and the findings as the
actionable result.
