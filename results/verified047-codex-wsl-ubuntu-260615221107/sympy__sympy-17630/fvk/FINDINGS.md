# FVK Findings

Status: constructed, not machine-checked. Findings are from public issue text
and static source/proof inspection only.

## F1: Scalar zero block entries break repeated multiplication

Classification: code bug, fixed.

Evidence: `benchmark/PROBLEM.md` reports that `b._blockmul(b).blocks[0, 1]`
has type `sympy.core.numbers.Zero`, and a subsequent `_blockmul` raises
`AttributeError: 'Zero' object has no attribute 'cols'`.

Input -> observed vs expected:

- Input: a valid block matrix `BlockMatrix([[a, z], [z, z]])`, where `a` is a
  `2 x 2` `MatrixSymbol` and `z` is `ZeroMatrix(2, 2)`.
- Observed before the fix: first block multiplication can store scalar `0` in
  zero result positions; repeated multiplication queries `.cols` on scalar `0`.
- Expected: each zero result position stores `ZeroMatrix(2, 2)`, so the result
  remains a valid `BlockMatrix` and can be multiplied again.

Trace: E1, E2 -> PO-3, PO-5. V1 fixed the scalar-zero case; V2 keeps that fix.

## F2: V1 normalized scalar zero but not every zero-like placeholder

Classification: proof-derived robustness gap, fixed in V2.

Evidence: `ZeroMatrix` and `GenericZeroMatrix` are matrix-zero representations,
but `GenericZeroMatrix` has no specified shape. V1 only normalized entries where
`not is_Matrix and block == 0`.

Input -> observed vs expected:

- Input: any valid aligned block multiplication whose raw product entry is a
  zero-matrix placeholder rather than a non-matrix scalar zero.
- Observed in V1 by static inspection: `_blockmul` would return that placeholder
  unchanged because it is matrix-like.
- Expected: every zero-like output block is rebuilt as
  `ZeroMatrix(rowblocksizes[i], colblocksizes[j])`.

Trace: E3, E4 -> PO-3. V2 changes the condition to normalize
`getattr(block, 'is_ZeroMatrix', False)` as well as scalar zero.

## F3: Broader arithmetic changes are not justified by the issue intent

Classification: rejected alternative.

Evidence: the reported failure is localized to `BlockMatrix._blockmul` returning
an invalid `BlockMatrix`. The source also has broad zero handling in `MatMul`,
`MatAdd`, and generic dense matrix arithmetic.

Input -> observed vs expected:

- Input: general matrix-expression addition or multiplication outside the
  block-grid product returned by `_blockmul`.
- Observed: no public issue evidence requires changing those semantics.
- Expected: leave broad matrix-expression arithmetic unchanged and repair the
  producer that has the output block dimensions needed to shape zero blocks.

Trace: PO-1, PO-7. No code change outside `blockmatrix.py`.

## F4: Existing tests must be kept until a real machine check or normal test run

Classification: verification/process limitation.

Evidence: the benchmark forbids running tests, Python, and K tooling. The FVK
proof is therefore constructed, not machine-checked.

Input -> observed vs expected:

- Input: current test suite, including hidden tests unavailable in this task.
- Observed: no test results are available.
- Expected: do not delete or modify tests; add no test-redundancy claim beyond
  the statement that future tests for the in-domain contract would be subsumed
  only after `kprove` returns `#Top`.

Trace: PO-8.
