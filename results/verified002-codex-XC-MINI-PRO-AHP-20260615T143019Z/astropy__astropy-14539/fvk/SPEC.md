# FVK Spec - astropy__astropy-14539

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Target

The audited unit is the table-column data comparison performed by
`TableDataDiff._diff` in `repo/astropy/io/fits/diff.py`, plus the new internal
helper `_vla_values_differ`.

The full FITS file parser/writer is outside the formal model. The model starts
at the point where `TableDataDiff` has already selected a common column, loaded
the two column data arrays, and is choosing the row-difference predicate.

## Intent Spec

1. `FITSDiff` must not report a data difference where no difference exists.
2. Comparing a FITS file to itself is in domain and must be reported as
   identical.
3. FITS binary table VLA columns using either `P` or `Q` descriptors are one
   format family for diff purposes. `Q` differs in descriptor size, not in row
   content comparison semantics.
4. Floating table values already use `where_not_allclose`, whose public helper
   behavior treats matching invalid floating values as not different.
5. The change must preserve non-VLA column comparison dispatch and existing `P`
   VLA dispatch.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation |
| --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md` | "`io.fits.FITSDiff` may sometimes report differences between identical files" | False positives in identical-input comparisons are defects. |
| E-002 | `benchmark/PROBLEM.md` | "Comparing a file to itself should never yield a difference." | Self-comparison is an in-domain reflexivity obligation. |
| E-003 | `benchmark/PROBLEM.md` | Reproducer creates `fits.Column('a', format='QD', array=[[0], [0, 0]])`. | `Q` VLA columns, specifically `QD`, must be handled. |
| E-004 | `benchmark/PROBLEM.md` public hint | "only `P` is handled in the diff code" and suggested adding `Q`. | `Q` must enter the VLA row-wise comparison path. |
| E-005 | `repo/astropy/io/fits/column.py` | `_ColumnFormat.__new__` sets `self.format` and handles `self.format in ("P", "Q")`. | It is valid to identify VLA columns by the normalized top-level format code. |
| E-006 | `repo/astropy/utils/diff.py` | `where_not_allclose` creates fixed masks to handle `INF` and `NaN`. | Floating row comparisons should reuse this helper to match FITSDiff's floating comparison policy. |
| E-007 | `repo/astropy/io/fits/tests/test_diff.py` | Existing public test `test_diff_nans` expects table/image diffs with matching NaNs to be identical. | Matching invalid floating values are not differences in FITSDiff. |

## Formal Contract

For each common table column `C` with equal row count:

1. If `C.format.format` is `P` or `Q`, compare the column row by row with
   `_vla_values_differ`.
2. `_vla_values_differ(a, b, rtol, atol)` returns `True` exactly when one of the
   following holds:
   - `a` and `b` have different shapes;
   - they are both floating arrays and `where_not_allclose(a, b, rtol, atol)`
     returns at least one differing index;
   - they are both non-floating numeric arrays and `np.allclose(a, b, rtol,
     atol)` is false;
   - they are non-numeric arrays and exact element equality finds at least one
     unequal element.
3. If all rows in a `P` or `Q` VLA column have equal shape and satisfy the
   appropriate row equality predicate, then the VLA branch contributes no row
   indices to `diffs`.
4. If either a `P` or `Q` VLA row has a different shape or fails the appropriate
   row equality predicate, that row index is included in `diffs`.
5. If `C.format.format` is not `P` or `Q`, the VLA helper is not used; the
   existing floating and generic comparison branches remain the dispatch
   mechanism.

## Frame Conditions

The fix does not alter public function signatures, the `FITSDiff` constructor,
`TableDataDiff` constructor parameters, report formatting, ignore-field
handling, column attribute comparison, row-count comparison, or diff aggregation
outside the row predicate used for VLA columns.

## Formal Files

The K artifacts are:

- `fvk/mini-fitsdiff.k`
- `fvk/fitsdiff-vla-spec.k`

They model only the branch predicate and row aggregation needed for this issue.
The proof is constructed in `fvk/PROOF.md`; it is not machine-checked.
