# FVK Proof Obligations

Status: constructed, not machine-checked.

## Obligations

### PO-1: Aligned block-matrix precondition

Given `self` and `other` are valid `BlockMatrix` instances and
`self.colblocksizes == other.rowblocksizes`, the aligned branch of `_blockmul`
is the intended branch.

Status: assumed from the branch guard and input domain.

### PO-2: Raw block product has the correct grid dimensions

`block_product = self.blocks * other.blocks` has
`block_product.rows == self.blockshape[0]` and
`block_product.cols == other.blockshape[1]`.

Status: discharged by the generic matrix multiplication dimension rule for an
`m x k` matrix times a `k x n` matrix.

### PO-3: Zero-like raw entries are replaced with shaped zero blocks

For every result position `(i, j)`, if `block_product[i, j]` is zero-like
(`is_ZeroMatrix` or scalar zero), `entry(i, j)` returns
`ZeroMatrix(self.rowblocksizes[i], other.colblocksizes[j])`.

Status: discharged by V2 source lines in `entry(i, j)`.

### PO-4: Non-zero matrix entries are preserved

For every result position `(i, j)`, if `block_product[i, j]` is not zero-like,
`entry(i, j)` returns `block_product[i, j]` unchanged.

Status: discharged by the final `return block` in `entry(i, j)`.

### PO-5: Returned block entries support future size queries

Every block in the returned `BlockMatrix` has usable `.rows` and `.cols`, so
`rowblocksizes`, `colblocksizes`, and repeated `_blockmul` do not query scalar
or shape-less zero objects.

Status: discharged by PO-3 for zero blocks and by the matrix-expression shape
rules for non-zero raw product entries. This is the obligation that removes the
reported `AttributeError`.

### PO-6: Result block sizes are the standard block product sizes

The result row block sizes equal `self.rowblocksizes`; the result column block
sizes equal `other.colblocksizes`.

Status: discharged by PO-3 for zero entries and by the aligned block product
shape rule for non-zero entries.

### PO-7: Fallback behavior is preserved

If `other` is not a `BlockMatrix` or the block sizes do not align, `_blockmul`
returns `self * other` as before.

Status: discharged by unchanged fallback branch.

### PO-8: Honesty gate

No claim is machine-checked in this session, and no test-redundancy action may
be taken.

Status: discharged by process: no tests, Python code, or K tooling were run, and
no test files were edited.

## K Commands To Run Later

These commands are recorded for a future environment with K installed; they were
not executed here.

```sh
cd fvk
kompile mini-blockmatrix.k --backend haskell
kast --backend haskell blockmatrix-spec.k
kprove blockmatrix-spec.k
```
