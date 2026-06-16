# Formal Spec In English

Status: constructed, not machine-checked.

## Claim C-SHAPE

Given matrices `A` and `B` with equal row count and normalized insertion
position `P`, `_eval_col_insert(P, B)` returns a matrix with `A.rows` rows and
`A.cols + B.cols` columns.

## Claim C-LEFT

For every result entry `(i, j)` with `0 <= j < P`, the result entry equals the
original matrix entry `A[i, j]`.

## Claim C-INSERT

For every result entry `(i, j)` with `P <= j < P + B.cols`, the result entry
equals the inserted matrix entry `B[i, j - P]`.

## Claim C-RIGHT

For every result entry `(i, j)` with `P + B.cols <= j < A.cols + B.cols`, the
result entry equals the original matrix entry `A[i, j - B.cols]`.

## Claim C-PUBLIC-GUARDS

The public `col_insert` method normalizes the requested position into the range
`0 <= P <= A.cols`, rejects unequal row counts through the existing
`ShapeError`, and otherwise delegates to `_eval_col_insert(P, other)`.

## Claim C-NULL

If `self` is a null matrix, the public `col_insert` method keeps the existing
special branch that returns a matrix constructed from `other` without invoking
`_eval_col_insert`.

## Frame conditions

No public signature changes, return-type changes, storage-format changes, or
test-file changes are part of the V1 fix. The proof assumes existing matrix
construction faithfully creates a result whose entries are supplied by the
entry function passed to `_new`.
