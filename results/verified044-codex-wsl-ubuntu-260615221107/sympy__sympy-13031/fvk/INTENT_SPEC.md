# Intent Spec

Status: constructed from public issue text, source comments/docstrings, and the
existing dense matrix join behavior. This is intent-only; candidate V1 behavior
is checked against it rather than used as an oracle.

## Required Behavior

1. `SparseMatrix.hstack` must behave like `Matrix.hstack` on compatible empty
   row matrices: horizontally stacking matrices with shapes `0 x n_i` returns a
   matrix with shape `0 x sum(n_i)`.
2. `SparseMatrix.vstack` must behave like `Matrix.vstack` on compatible empty
   column matrices: vertically stacking matrices with shapes `n_i x 0` returns a
   matrix with shape `sum(n_i) x 0`.
3. Non-empty compatible sparse joins keep existing sparse semantics:
   `row_join` requires equal row counts unless the left operand has zero
   columns, and returns `(rows, left_cols + right_cols)`.
4. Non-empty compatible sparse joins keep existing sparse semantics:
   `col_join` requires equal column counts unless the left operand has zero
   rows, and returns `(left_rows + right_rows, cols)`.
5. The existing generic null-matrix adaptation rule is part of the intended
   compatibility surface: a left operand with zero columns may adapt to the
   right operand's row count for `row_join`, and a left operand with zero rows
   may adapt to the right operand's column count for `col_join`.
6. The public sparse matrix API should not change signatures or stop returning
   sparse matrices from the sparse-specific join path.

## Domain Assumptions

- Matrix dimensions are nonnegative integers.
- The audited observable is shape. Sparse entry copying is a frame condition:
  for nonzero entries, existing sparse join code shifts indices by the old row
  or column count and V1 does not alter that path.
- Partial correctness only: no termination proof is attempted. The reduced
  shape semantics has structural recursion over finite argument lists.
