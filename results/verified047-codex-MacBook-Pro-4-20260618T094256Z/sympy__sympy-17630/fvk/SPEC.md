# Specification

Status: constructed, not machine-checked.

## Target

`BlockMatrix._blockmul(self, other)` has three observable branches:

1. `other` is a `BlockMatrix` and block sizes are compatible.
2. `other` is a `BlockMatrix` but block sizes are incompatible.
3. `other` is not a `BlockMatrix`.

## Contract

For branch 1, `_blockmul` returns a `BlockMatrix` whose raw block-grid product
entries are post-processed as follows:

- If a raw product entry is a matrix block, return that block unchanged.
- If a raw product entry is exact scalar `0`, return
  `ZeroMatrix(self.rowblocksizes[i], other.colblocksizes[j])`.

The result's row block sizes are those of `self`; the result's column block
sizes are those of `other`.

For branches 2 and 3, `_blockmul` returns the ordinary multiplication expression
`self * other`, preserving the pre-existing fallback behavior.

## Mini-Semantics Mapping

The K artifacts use a small block-matrix model:

- `blockMul(A, block(B))` represents `_blockmul` with a `BlockMatrix` right
  operand.
- `blockMul(A, nonBlock(X))` represents `_blockmul` with a non-`BlockMatrix`
  right operand.
- `compatible(A, B)` abstracts
  `self.colblocksizes == other.rowblocksizes`.
- `rawEntry(A, B, I, J)` abstracts the explicit matrix product
  `self.blocks*other.blocks` at result block position `(I, J)`.
- `scalarZero` abstracts the exact scalar `0` that caused the reported
  `AttributeError`.
- `zeroMatrix(R, C)` abstracts `ZeroMatrix(R, C)`.
- `product(A, B)` abstracts the resulting `BlockMatrix`.

The model intentionally treats raw product entries as either matrix blocks or
the exact scalar-zero artifact. A nonzero scalar raw entry is outside the public
issue and outside the `BlockMatrix` block-entry invariant.

## Evidence Mirror

Critical evidence is mirrored from `PUBLIC_EVIDENCE_LEDGER.md`:

- E1-E3 derive the scalar-zero normalization obligation from the public issue.
- E4-E5 derive the matrix-shaped block invariant from the class docstring and
  shape-accessing properties.
- E6 derives the non-`BlockMatrix` fallback frame condition from public in-repo
  tests.
- E7 derives the compatibility precondition from the implementation branch
  shape, not from current behavior as desired output.

## Verification Scope

There are no loops or recursive calls in the audited code path, so no circularity
claim is needed.

The proof is partial correctness over the mini-semantics. It is constructed but
not machine-checked in this environment.
