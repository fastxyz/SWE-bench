# Intent Spec

Status: constructed, not machine-checked.

## Required behavior

For `Matrix.col_insert(pos, other)`, public intent requires inserting the
columns of `other` into `self` at the requested column position while preserving
the entries and row placement of the original matrix.

For the normalized insertion position `P`, original matrix `A` with `R` rows
and `C` columns, and inserted matrix `B` with `R` rows and `K` columns, the
result must have shape `R x (C + K)` and entries:

- left of the insertion point: `result[i, j] = A[i, j]` for `j < P`;
- inside the inserted block: `result[i, j] = B[i, j - P]` for
  `P <= j < P + K`;
- right of the inserted block: `result[i, j] = A[i, j - K]` for
  `P + K <= j < C + K`.

The public `col_insert` method additionally normalizes `pos` into
`0 <= P <= C`, preserves the existing shape guard requiring equal row counts,
and keeps its existing null-matrix branch.

## Out of scope

The audit does not redefine matrix construction internals, element
simplification, sparse storage, or display formatting. Those are trusted as
existing matrix infrastructure. The proof targets the entry-selection logic
changed by V1 and the public guards that feed it.
