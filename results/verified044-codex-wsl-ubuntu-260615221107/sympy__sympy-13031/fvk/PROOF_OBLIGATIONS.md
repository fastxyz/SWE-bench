# PROOF_OBLIGATIONS.md

Status: constructed, not machine-checked.

## PO1: Row Join Null-Column Adaptation

For all `r1, r2, c2 >= 0`,
`row_join(shape(r1, 0), shape(r2, c2)) = shape(r2, c2)`.

Justification: mirrors `MatrixShaping.row_join` for a left operand with zero
columns and is required to avoid treating all zero-size matrices as
dimensionless.

## PO2: Row Join Compatible Accumulation

For all `r, c1, c2 >= 0` with `c1 != 0`,
`row_join(shape(r, c1), shape(r, c2)) = shape(r, c1 + c2)`.

Justification: ordinary horizontal shape arithmetic.

## PO3: Col Join Null-Row Adaptation

For all `c1, r2, c2 >= 0`,
`col_join(shape(0, c1), shape(r2, c2)) = shape(r2, c2)`.

Justification: mirrors `MatrixShaping.col_join` for a left operand with zero
rows and is required to avoid treating all zero-size matrices as dimensionless.

## PO4: Col Join Compatible Accumulation

For all `r1, r2, c >= 0` with `r1 != 0`,
`col_join(shape(r1, c), shape(r2, c)) = shape(r1 + r2, c)`.

Justification: ordinary vertical shape arithmetic.

## PO5: HStack Zero-Row Family

For all `c0, c1, c2, c3 >= 0`,
`hstack(shape(0,c0), shape(0,c1), shape(0,c2), shape(0,c3))`
returns `shape(0, c0 + c1 + c2 + c3)`.

Justification: direct public issue example, generalized over all nonnegative
column counts.

## PO6: VStack Zero-Column Family

For all `r0, r1, r2, r3 >= 0`,
`vstack(shape(r0,0), shape(r1,0), shape(r2,0), shape(r3,0))`
returns `shape(r0 + r1 + r2 + r3, 0)`.

Justification: direct public issue hint, generalized over all nonnegative row
counts.

## PO7: ShapeError Preservation Outside Null Adaptation

For `row_join`, if the left operand has nonzero columns and row counts differ,
the operation reaches `shapeError`. For `col_join`, if the left operand has
nonzero rows and column counts differ, the operation reaches `shapeError`.

Justification: preserves the public shape-compatibility checks outside the
generic null-matrix adaptation case.

## PO8: API and Sparse Return Compatibility

V1 must not change the public method signatures or redirect public
`SparseMatrix` calls away from the sparse-specific implementation.

Justification: the issue asks for a simple release fix, not an API redesign.
The issue discussion notes a broader `_eval_row_join`/`_eval_col_join` cleanup,
but that is an unresolved design topic rather than required behavior.
