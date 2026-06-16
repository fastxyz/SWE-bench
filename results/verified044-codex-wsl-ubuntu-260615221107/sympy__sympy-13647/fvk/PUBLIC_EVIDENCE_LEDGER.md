# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | prompt | "`Matrix.col_insert()` no longer seems to work correctly." | Treat current implementation as candidate behavior to check, not as the spec. | Encoded in `SPEC.md` and `col-insert-spec.k`. |
| E2 | prompt | "`M.col_insert(3, V)`" where `M` is `eye(6)` and `V` has two inserted columns. | The contract covers arbitrary valid insertion positions and multi-column insertion, not only append/prepend or one-column cases. | Encoded as `K >= 0` and `0 <= P <= C`, with a specific multi-column finding. |
| E3 | prompt | "The 3 x 3 identity matrix to the right of the columns of twos is shifted from the bottom three rows to the top three rows." | Columns to the right of the inserted block must preserve their original row placements and values, shifted right only by inserted column count. | Encoded as the right-frame postcondition `A[i, j - K]`. |
| E4 | public hint | "`pos` shouldn't be here" at the old post-insertion source index. | The right-frame mapping must not subtract `pos`; subtracting only `other.cols` is the intended index transformation. | Encoded in PO-5 and the V1 source decision. |
| E5 | docstring/name | "Insert one or more columns at the given column position." | Result shape and entry mapping are insertion semantics: original columns before/after the insertion remain in order, inserted columns occupy the interval starting at `P`. | Encoded in SPEC and proof obligations. |
| E6 | public source | `col_insert` normalizes negative and out-of-range positions, checks row count, then calls `_eval_col_insert`. | The helper proof may assume normalized `P` and equal row counts; public method obligations include preserving these guards. | Encoded in PO-1, PO-2, PO-6. |
| E7 | public source | Sparse `_eval_col_insert` shifts existing columns `col += other.cols` when `col >= icol`. | Independent implementation evidence supports the same right-frame shift by inserted width only. | Used as compatibility/supporting evidence, not as sole intent source. |
| E8 | public tests | Existing one-column zero-matrix tests compare to Python list insertion. | Tests support position normalization and basic insertion, but do not cover nonzero right-side preservation. | Recorded as test gap F-003, not used to weaken the spec. |
| E9 | public source comment | "Allows you to build a matrix even if it is null matrix." | The existing null-matrix branch of `col_insert` returns a matrix built from `other` before calling `_eval_col_insert`. | Encoded as PO-10; unchanged by V1. |
