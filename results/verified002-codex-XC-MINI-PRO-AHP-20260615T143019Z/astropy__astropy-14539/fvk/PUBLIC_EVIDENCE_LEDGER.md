# Public Evidence Ledger

| ID | Source | Quote or pointer | Obligation |
| --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md` | "`io.fits.FITSDiff` may sometimes report differences between identical files" | Eliminate false-positive data differences. |
| E-002 | `benchmark/PROBLEM.md` | "Comparing a file to itself should never yield a difference." | Reflexivity for self-comparison. |
| E-003 | `benchmark/PROBLEM.md` | `fits.Column('a', format='QD', array=[[0], [0, 0]])` | `QD` VLA columns are in-domain. |
| E-004 | `benchmark/PROBLEM.md` | "only `P` is handled in the diff code" | `Q` must be handled like `P` for VLA diff. |
| E-005 | `repo/astropy/io/fits/column.py` | `_ColumnFormat.__new__` stores `self.format` and handles `("P", "Q")`. | Use normalized top-level format code. |
| E-006 | `repo/astropy/utils/diff.py` | `where_not_allclose` handles invalid floating values. | Floating VLA rows should use the same policy. |
| E-007 | `repo/astropy/io/fits/tests/test_diff.py` | `test_diff_nans` expects matching NaNs to be identical. | Matching invalid floating values are not differences. |
