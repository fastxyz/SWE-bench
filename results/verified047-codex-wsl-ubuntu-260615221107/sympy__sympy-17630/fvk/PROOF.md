# FVK Proof

Status: constructed, not machine-checked. This proof was built by static
reasoning over the source and the abstract K-style model; no commands were run.

## Claims

`BM-MUL-NORMALIZES-ZEROS`: for valid aligned block matrices, `_blockmul`
returns a `BlockMatrix` whose zero result blocks are `ZeroMatrix` objects with
the corresponding output block dimensions.

`BM-MUL-PRESERVES-NONZERO-BLOCKS`: for valid aligned block matrices, non-zero
raw product blocks are preserved unchanged.

`BM-MUL-FALLBACK-FRAME`: outside the valid aligned block-matrix branch,
`_blockmul` keeps the previous fallback behavior.

## Constructed Proof

1. By PO-1, the verified branch is entered only when both operands are
   `BlockMatrix` instances and their block sizes align.
2. By matrix multiplication dimensions, `self.blocks * other.blocks` produces a
   raw block grid with one row for each block row in `self` and one column for
   each block column in `other` (PO-2).
3. The implementation stores `rowblocksizes = self.rowblocksizes` and
   `colblocksizes = other.colblocksizes`. These are exactly the output block
   dimensions required by the block product contract.
4. For an arbitrary output position `(i, j)`, `entry(i, j)` reads the raw block.
   If the block is zero-like, the V2 guard is true and returns
   `ZeroMatrix(rowblocksizes[i], colblocksizes[j])`. This proves PO-3 for scalar
   zero, concrete `ZeroMatrix`, and shape-less zero-matrix placeholders.
5. If the raw block is not zero-like, `entry(i, j)` returns it unchanged. The
   raw product is the standard block multiplication sum for that position, so
   preserving it proves PO-4.
6. The returned nested list comprehensions cover every `(i, j)` in the raw
   product grid exactly once, and `BlockMatrix([...])` receives matrix-shaped
   entries at every zero position. Together with the matrix-expression shape
   rules for non-zero entries, PO-5 and PO-6 hold.
7. The fallback branch is textually unchanged, proving PO-7.

By universal generalization over `(i, j)`, all result blocks satisfy the
matrix-shaped block invariant. Therefore a later call to `colblocksizes` or
`rowblocksizes` cannot encounter the scalar `Zero` that caused the reported
exception, provided the inputs to the verified branch are valid `BlockMatrix`
instances.

## Adequacy And Completeness Check

The proof covers the full public intent of this issue: the producer of invalid
zero block entries in repeated block multiplication is repaired, and no unrelated
matrix-expression behavior is changed. It does not attempt to repair already
invalid `BlockMatrix` instances constructed outside `_blockmul`; the public
issue starts from a valid `BlockMatrix` with `ZeroMatrix` blocks.

## Residual Risk

- The proof is constructed, not machine-checked.
- The mini-K model is abstract and property-complete for block dimensions and
  zero normalization, but it is not a full Python or SymPy semantics.
- Termination is immediate from finite list comprehensions over finite block
  grids, but no separate total-correctness machine proof was run.
- Future broad changes to `MatAdd`, `MatMul`, or dense matrix multiplication
  could introduce new zero-like representations; PO-3 is intentionally written
  to normalize the known zero predicates used in this codebase.

## Future Machine Check

```sh
cd fvk
kompile mini-blockmatrix.k --backend haskell
kast --backend haskell blockmatrix-spec.k
kprove blockmatrix-spec.k
```

Expected outcome after a real K implementation accepts the abstract model:
`kprove` returns `#Top` for the claims.
