# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent
and static source inspection only.

## F-001: V1 Broke The Public NdarrayMixin Re-Export

Input -> observed vs expected:

- Input: package import resolution for `from astropy.table import NdarrayMixin`.
- Observed in V1 by static source inspection: `astropy.table.__init__` imports
  `NdarrayMixin` from `.table`, but V1 removed the `NdarrayMixin` binding from
  `table.py`.
- Expected: the behavior fix must not remove the public class export.

Classification: code bug introduced by V1; compatibility regression.

Resolution: fixed in V2 by restoring
`from .ndarray_mixin import NdarrayMixin  # noqa: F401` in
`repo/astropy/table/table.py`. The import is retained as a public re-export,
not as conversion logic.

Trace: SPEC C3, PROOF_OBLIGATIONS PO-004.

## F-002: Existing Public Test Encodes Legacy Bug

Input -> observed vs expected:

- Input: `Table([structured_array], names=["a"])` and later assignment of
  structured arrays as columns.
- Observed in `repo/astropy/table/tests/test_mixin.py`: `test_ndarray_mixin`
  asserts `isinstance(t["a"], NdarrayMixin)` and the same for other plain
  structured arrays.
- Expected from the issue and public hints: plain structured arrays should
  become regular structured columns through `ColumnClass`.

Classification: SUSPECT legacy test evidence, not a reason to preserve the old
production behavior.

Resolution: no test files were modified, per task constraints. A future public
test update should assert `Column`/normal column behavior for plain structured
arrays while keeping explicit `NdarrayMixin` coverage.

Trace: SPEC E6, PROOF_OBLIGATIONS PO-001 and PO-005.

## F-003: V2 Discharges The Conversion Intent

Input -> observed vs expected:

- Input: a non-Column, non-mixin structured `np.ndarray` with no mixin handler.
- Observed in V2 by static control flow: the legacy view-to-`NdarrayMixin`
  branch is gone; after name resolution, the data reaches the normal
  `ColumnClass` construction branch.
- Expected: structured data is added as a structured column, not an
  `NdarrayMixin`.

Classification: confirmed obligation, no further source edit required.

Trace: SPEC C1, PROOF_OBLIGATIONS PO-001 and PO-002.

## F-004: No Machine Check Was Run

Input -> observed vs expected:

- Input: FVK proof commands for the mini K model.
- Observed: commands are recorded in `fvk/PROOF.md` but were not executed.
- Expected: per task constraints, do not run `kompile`, `kprove`, Python, or
  tests in this environment.

Classification: proof-status limitation, not a code bug.

Resolution: treat the proof as constructed, not machine-checked; do not remove
tests based on it until the commands and normal test suite run in a suitable
environment.

Trace: PROOF_OBLIGATIONS PO-006.
