# Baseline Notes

## Root cause

`SparseMatrix.hstack` and `SparseMatrix.vstack` reduce through the mutable sparse
`row_join` and `col_join` implementations. Those methods treated any matrix with
`len(self) == 0` as a generic null matrix:

```python
if not self:
    return type(self)(other)
```

For sparse matrices with one zero dimension, such as `0 x n` or `n x 0`, this
discarded the existing empty matrix shape instead of accumulating the compatible
dimension. As a result, horizontally stacking `0 x 0`, `0 x 1`, `0 x 2`, and
`0 x 3` sparse matrices kept replacing the intermediate result with the next
argument and ended at `0 x 3` instead of `0 x 6`. The same issue applied
vertically for `n x 0` sparse matrices.

Dense matrices avoided this through the shared `MatrixShaping.row_join` and
`MatrixShaping.col_join` logic, which only widens the truly unconstrained null
dimension and otherwise lets shape-compatible empty matrices contribute their
row or column counts.

## Changed files

`repo/sympy/matrices/sparse.py`

- Updated `MutableSparseMatrix.col_join` to replace the broad falsy-matrix
  shortcut with the same zero-row compatibility rule used by the common matrix
  implementation. A `0 x n` sparse matrix can now be adjusted only when its
  column count is unconstrained by the join target; otherwise compatible zero
  row matrices still join through the normal sparse path and preserve columns.
- Updated `MutableSparseMatrix.row_join` similarly for zero-column sparse
  matrices. Compatible `n x 0` matrices now preserve and accumulate row counts
  instead of being replaced by the right-hand argument.

## Assumptions and alternatives

- I assumed the intended behavior for sparse joins should match the dense
  `MatrixShaping` behavior described in the issue hints, including the existing
  rule that a true null dimension can be adapted before joining.
- I kept the sparse-specific join implementation rather than removing it or
  delegating wholesale to `MatrixShaping`, because the existing sparse code
  preserves sparse return types and efficiently copies sparse entries.
- I considered adding `_eval_row_join`/`_eval_col_join` and removing the sparse
  `row_join`/`col_join` overrides, as suggested in the issue discussion, but
  rejected that as a larger API cleanup. The minimal bug fix is to align the
  existing sparse overrides with the already-fixed common null-matrix rules.
- I did not change tests, per the benchmark instructions.
- I did not run tests or execute SymPy code, per the benchmark instructions.
