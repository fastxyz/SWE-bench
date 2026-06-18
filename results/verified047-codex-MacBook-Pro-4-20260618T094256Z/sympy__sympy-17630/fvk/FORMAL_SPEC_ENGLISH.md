# Formal Spec English

Status: constructed, not machine-checked.

## Claim Paraphrases

`NORMALIZE-SCALAR-ZERO`

For any nonnegative result block dimensions `R` and `C`, normalizing exact scalar
zero returns `zeroMatrix(R, C)`. This corresponds to V1 returning
`ZeroMatrix(rowblocksizes[i], colblocksizes[j])` when the raw product entry is
scalar `0`.

`NORMALIZE-MATRIX-PRESERVE`

For any matrix block `MB`, normalizing `MB` returns `MB` unchanged. This is the
frame condition that nonzero or already-shaped matrix entries are not rewritten.

`BLOCKMUL-COMPATIBLE-ZERO-ENTRY`

For any compatible block matrices `A` and `B`, and any valid result block
position `(I, J)`, if the raw explicit block-grid product at `(I, J)` is exact
scalar zero, the result block entry is `zeroMatrix(rowSize(A, I), colSize(B, J))`.

`BLOCKMUL-COMPATIBLE-MATRIX-ENTRY`

For any compatible block matrices `A` and `B`, and any valid result block
position `(I, J)`, if the raw explicit block-grid product at `(I, J)` is already
a matrix block `MB`, the result block entry is exactly `MB`.

`BLOCKMUL-RESULT-ROW-SHAPE`

For any compatible product `product(A, B)`, every result row block size at row
index `I` is `rowSize(A, I)`.

`BLOCKMUL-RESULT-COL-SHAPE`

For any compatible product `product(A, B)`, every result column block size at
column index `J` is `colSize(B, J)`.

`BLOCKMUL-REPEATED-SAFE`

For any compatible product `product(A, B)`, every valid result block entry is a
matrix entry. Therefore a later block multiplication can read shape information
from the result entries rather than failing on scalar zero.

`BLOCKMUL-NONBLOCK-FALLBACK`

If `_blockmul` is called with a non-`BlockMatrix` right operand, it returns the
ordinary multiplication fallback. V1 does not change this branch.

`BLOCKMUL-INCOMPATIBLE-FALLBACK`

If `_blockmul` is called with another `BlockMatrix` whose block sizes are not
compatible for block multiplication, it returns the ordinary multiplication
fallback. V1 does not change this branch.

## Side Conditions

The result-entry claims require `compatible(A, B)` and valid result block
indices. This mirrors the implementation branch condition and normal indexed
block access domain.

The scalar-zero normalization claim requires nonnegative result dimensions,
matching the dimension domain for `ZeroMatrix`.

The model assumes raw product entries are either matrix blocks or exact scalar
zero. This is the issue-local block-entry domain: scalar zero is the non-matrix
artifact being repaired.

## Frame Conditions

The formal claims preserve:

- matrix-valued raw product entries;
- non-`BlockMatrix` fallback behavior;
- incompatible-`BlockMatrix` fallback behavior;
- result row and column block-size provenance.

## Circularities

There are no loop or recursive back-edges in `_blockmul`, so no circularity claim
is required.
