# Public Evidence Ledger

## E1: Original Regression

- Source: prompt / issue.
- Evidence: `Matrix.hstack(Matrix.zeros(0, 0), Matrix.zeros(0, 1), Matrix.zeros(0, 2), Matrix.zeros(0, 3)).shape` returned `(0, 6)` in SymPy 1.0, but `(0, 3)` in SymPy 1.1.
- Obligation: horizontal stacking of zero-row matrices must accumulate column
  counts, including for empty matrices.
- Status: encoded in `HSTACK-ZERO-ROWS-FOUR` and generalized in the proof
  obligations.

## E2: Dense Baseline and Sparse Gap

- Source: public issue hint.
- Evidence: dense `Matrix.hstack(*[Matrix.zeros(0, n) for n in range(4)])`
  gives `Matrix(0, 6, [])`, while sparse
  `SparseMatrix.hstack(*[SparseMatrix.zeros(0, n) for n in range(4)])` gives
  `Matrix(0, 3, [])`.
- Obligation: sparse horizontal joins should match the dense shape rule.
- Status: encoded in `HSTACK-ZERO-ROWS-FOUR`; mismatch recorded as F1 in
  `FINDINGS.md`.

## E3: Vertical Family

- Source: public issue hint.
- Evidence: `[Matrix.zeros(n, 0) for n in range(4)]` under `Matrix.vstack`
  has shape `(6, 0)`.
- Obligation: sparse vertical joins over zero-column matrices should accumulate
  row counts.
- Status: encoded in `VSTACK-ZERO-COLS-FOUR`; mismatch recorded as the vertical
  counterpart of F1.

## E4: Dense Null-Matrix Rule in Source

- Source: `repo/sympy/matrices/common.py`.
- Evidence: `row_join` adapts `self._new(other.rows, 0, []).row_join(other)`
  when `self.cols == 0 and self.rows != other.rows`; `col_join` adapts
  `self._new(0, other.cols, []).col_join(other)` when
  `self.rows == 0 and self.cols != other.cols`.
- Obligation: sparse overrides should not bypass this intended compatibility
  rule for empty shapes.
- Status: encoded in `ROW-JOIN-ZERO-COL` and `COL-JOIN-ZERO-ROW`.

## E5: Sparse Public Alias

- Source: `repo/sympy/matrices/__init__.py`.
- Evidence: `SparseMatrix = MutableSparseMatrix`.
- Obligation: the fix must target `MutableSparseMatrix.row_join` and
  `MutableSparseMatrix.col_join` for the public `sympy.matrices.SparseMatrix`
  API used by the issue.
- Status: satisfied by V1; audited in `PUBLIC_COMPATIBILITY_AUDIT.md`.

## E6: Sparse Join Implementation

- Source: `repo/sympy/matrices/sparse.py`.
- Evidence before V1: both `row_join` and `col_join` returned
  `type(self)(other)` on `if not self`, where `not self` means
  `rows * cols == 0`.
- Obligation: a zero-size sparse matrix with a meaningful empty dimension must
  still contribute that compatible dimension to shape arithmetic.
- Status: mismatch recorded as F1; fixed by V1.
