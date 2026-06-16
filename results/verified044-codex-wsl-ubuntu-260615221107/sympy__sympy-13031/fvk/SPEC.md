# SPEC.md

Status: FVK formalization, constructed but not machine-checked.

## Scope

The audited unit is the shape behavior of sparse matrix joins in
`repo/sympy/matrices/sparse.py`, specifically
`MutableSparseMatrix.row_join`, `MutableSparseMatrix.col_join`, and the inherited
`hstack`/`vstack` reductions that call them.

The formal model verifies shape only. This is intentionally property-complete
for the reported issue: the public examples assert `.shape` or print empty
matrices as `Matrix(rows, cols, [])`.

## Public Intent Ledger

- E1: The issue reports that horizontally stacking dense zero-row matrices with
  column counts `0, 1, 2, 3` should produce shape `(0, 6)`.
- E2: The issue hint states dense `Matrix` has been fixed but `SparseMatrix`
  still returns `Matrix(0, 3, [])` for the same sparse inputs.
- E3: The issue hint includes the vertical counterpart:
  `Matrix.vstack(*[Matrix.zeros(n, 0) for n in range(4)]).shape == (6, 0)`.
- E4: The generic dense/common join code adapts only the unconstrained null
  dimension before enforcing shape compatibility.
- E5: The public `SparseMatrix` imported from `sympy.matrices` aliases
  `MutableSparseMatrix`, so V1 edits the public dispatch target.

The full ledger is mirrored in `PUBLIC_EVIDENCE_LEDGER.md`.

## Shape Contract

Let `shape(r, c)` denote a sparse matrix shape with nonnegative integer
dimensions.

`row_join(shape(r1, c1), shape(r2, c2))`:

- If `c1 == 0`, the result shape is `shape(r2, c2)`. This is the common
  null-column adaptation rule; when `r1 == r2` it is also the ordinary
  compatible result `shape(r1, c2)`.
- If `c1 != 0` and `r1 == r2`, the result shape is
  `shape(r1, c1 + c2)`.
- If `c1 != 0` and `r1 != r2`, the operation reaches `shapeError`.

`col_join(shape(r1, c1), shape(r2, c2))`:

- If `r1 == 0`, the result shape is `shape(r2, c2)`. This is the common
  null-row adaptation rule; when `c1 == c2` it is also the ordinary compatible
  result `shape(r2, c1)`.
- If `r1 != 0` and `c1 == c2`, the result shape is
  `shape(r1 + r2, c1)`.
- If `r1 != 0` and `c1 != c2`, the operation reaches `shapeError`.

`hstack` and `vstack` are left reductions through `row_join` and `col_join`,
respectively, matching `MatrixShaping.hstack` and `MatrixShaping.vstack`.

## Required Instances

- For all `c0, c1, c2, c3 >= 0`,
  `hstack(0xc0, 0xc1, 0xc2, 0xc3)` has shape
  `0 x (c0 + c1 + c2 + c3)`.
- For all `r0, r1, r2, r3 >= 0`,
  `vstack(r0x0, r1x0, r2x0, r3x0)` has shape
  `(r0 + r1 + r2 + r3) x 0`.
- For all common rows `r >= 0`, compatible nonempty horizontal stacking
  preserves row count and sums columns.
- For all common columns `c >= 0`, compatible nonempty vertical stacking sums
  rows and preserves column count.

## Formal Artifacts

- `mini-sparse-join.k`: reduced K semantics for shape-level sparse join
  operations.
- `sparse-join-spec.k`: K claims for row/column join and four-argument stack
  obligations.
- `FORMAL_SPEC_ENGLISH.md`: English paraphrase of every nontrivial K claim.
- `SPEC_AUDIT.md`: adequacy check from intent to formal English.
- `PUBLIC_COMPATIBILITY_AUDIT.md`: API and dispatch compatibility audit.
