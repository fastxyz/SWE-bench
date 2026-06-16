# Baseline Notes

## Root cause

`BlockMatrix._blockmul` delegates multiplication of the block grid to ordinary
`Matrix` multiplication with `self.blocks * other.blocks`. That multiplication
computes each output entry as a sum over block products. When every term in one
output block is matrix-shaped zero, the dense matrix arithmetic can simplify the
entry to scalar `0` instead of preserving a `ZeroMatrix` with the output block's
shape.

The resulting `BlockMatrix` can therefore contain scalar `Zero` objects in its
`blocks` matrix. Later block operations query `.rows` and `.cols` on those block
entries through `rowblocksizes` and `colblocksizes`, causing the reported
`AttributeError`.

## Changed files

- `repo/sympy/matrices/expressions/blockmatrix.py`: updated
  `BlockMatrix._blockmul` to normalize scalar zero entries produced by the
  intermediate block-grid product back into `ZeroMatrix(row_size, col_size)`.
  The row size comes from the left block matrix and the column size comes from
  the right block matrix, which are exactly the dimensions of the corresponding
  output block.

## Assumptions and alternatives

- I assumed a valid `BlockMatrix` should always store matrix-shaped block
  entries, including zero blocks. Scalar zero is only an implementation artifact
  of the intermediate dense block-grid multiplication.
- I kept the fix local to `_blockmul` because the issue is triggered by repeated
  block multiplication and this method has the output block sizes needed to
  rebuild shaped zeros without guessing.
- I considered changing `ZeroMatrix` arithmetic or generic dense matrix
  multiplication, but rejected that as too broad for this issue because those
  paths affect many matrix-expression operations outside block multiplication.
- I considered relaxing `rowblocksizes` and `colblocksizes` to tolerate scalar
  zeros, but rejected that because a scalar zero does not carry enough shape
  information in general; preserving the shaped zero at construction time keeps
  the `BlockMatrix` invariant intact.

No tests or project code were run, per the benchmark instruction.
