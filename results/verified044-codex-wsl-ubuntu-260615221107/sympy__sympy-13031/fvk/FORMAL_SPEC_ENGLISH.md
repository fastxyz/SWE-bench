# Formal Spec English

This file paraphrases the nontrivial K claims in
`fvk/sparse-join-spec.k`.

## Join Claims

- `ROW-JOIN-ZERO-COL`: for any nonnegative row counts `R1`, `R2` and right
  column count `C2`, joining a left sparse matrix of shape `R1 x 0` with a
  right sparse matrix of shape `R2 x C2` returns shape `R2 x C2`.
- `ROW-JOIN-COMPAT`: for compatible sparse matrices with equal row count `R`
  and nonzero left column count `C1`, `row_join` returns shape
  `R x (C1 + C2)`.
- `ROW-JOIN-ERROR`: if the left matrix has nonzero columns and the row counts
  differ, `row_join` reaches `shapeError`.
- `COL-JOIN-ZERO-ROW`: for any nonnegative column counts `C1`, `C2` and right
  row count `R2`, joining a left sparse matrix of shape `0 x C1` above a right
  sparse matrix of shape `R2 x C2` returns shape `R2 x C2`.
- `COL-JOIN-COMPAT`: for compatible sparse matrices with equal column count `C`
  and nonzero left row count `R1`, `col_join` returns shape `(R1 + R2) x C`.
- `COL-JOIN-ERROR`: if the left matrix has nonzero rows and the column counts
  differ, `col_join` reaches `shapeError`.

## Stack Claims

- `HSTACK-ZERO-ROWS-FOUR`: for any four nonnegative column counts, horizontally
  stacking shapes `0 x C0`, `0 x C1`, `0 x C2`, and `0 x C3` returns shape
  `0 x (C0 + C1 + C2 + C3)`.
- `VSTACK-ZERO-COLS-FOUR`: for any four nonnegative row counts, vertically
  stacking shapes `R0 x 0`, `R1 x 0`, `R2 x 0`, and `R3 x 0` returns shape
  `(R0 + R1 + R2 + R3) x 0`.
- `HSTACK-COMPAT-NONEMPTY-FOUR`: for any common nonnegative row count `R`,
  horizontally stacking four matrices with row count `R` returns row count `R`
  and the sum of the column counts.
- `VSTACK-COMPAT-NONEMPTY-FOUR`: for any common nonnegative column count `C`,
  vertically stacking four matrices with column count `C` returns the sum of
  the row counts and column count `C`.

## Frame Claims

- The K model abstracts sparse entries away and observes only shape. This is
  adequate for the issue because every public example and expected result in
  the issue is expressed as `.shape` or `Matrix(rows, cols, [])`.
- Sparse return type and API signature compatibility are checked in
  `PUBLIC_COMPATIBILITY_AUDIT.md`, not encoded as a K shape claim.
