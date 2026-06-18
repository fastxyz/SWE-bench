# Baseline Notes

## Root cause

`BlockMatrix._blockmul` multiplies the block grid with ordinary explicit matrix
multiplication: `self.blocks*other.blocks`. For a block result whose summands
are all `ZeroMatrix` instances, that explicit multiplication path can simplify
the entry to the scalar `0` instead of a shaped `ZeroMatrix`. The resulting
`BlockMatrix` then contains a scalar in a block position. A later block
multiplication asks that scalar for `.rows` or `.cols` through
`rowblocksizes`/`colblocksizes`, which raises `AttributeError`.

## Changed files

`repo/sympy/matrices/expressions/blockmatrix.py`

`BlockMatrix._blockmul` now post-processes the computed block-grid product.
For each result entry, exact scalar zero entries are replaced with
`ZeroMatrix(row_block_size, col_block_size)` using the row block sizes from
the left operand and the column block sizes from the right operand. Nonzero
entries and entries that are already matrix expressions are left unchanged.

## Assumptions

The intended invariant is that every entry of a `BlockMatrix` is a matrix-like
block with a shape. A scalar `0` produced internally during block multiplication
is therefore an implementation artifact, not a valid block entry.

Only exact scalar zero needs special handling for this issue. Other non-matrix
scalar entries should still be rejected by the existing `BlockMatrix`
construction rules rather than silently converted.

## Alternatives considered

Changing the general explicit matrix multiplication code to avoid `Add` for
matrix-expression entries would address the underlying simplification path, but
that code is shared broadly and would be a larger behavioral change.

Changing `BlockMatrix.__new__` to accept scalar zeros was also considered, but
that would broaden the public constructor behavior. The narrower fix is to
repair the internal `_blockmul` result at the point where the result block sizes
are known unambiguously.
