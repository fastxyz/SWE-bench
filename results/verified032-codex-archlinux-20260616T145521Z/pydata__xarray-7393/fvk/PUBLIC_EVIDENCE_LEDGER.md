# Public Evidence Ledger

Status: constructed, not machine-checked.

## Ledger

E1. Source: `benchmark/PROBLEM.md`

Quoted evidence: "Creating a MultiIndex should not change the data type of the
Indexes from which it is built."

Semantic obligation: dtype preservation for level coordinates created from
stacked xarray indexes.

Status: encoded by `SPEC.md` B1, B3, and B4; formalized by claim
`MI-ARRAY-DEFAULT-LEVEL-DTYPE`.

E2. Source: `benchmark/PROBLEM.md`

Quoted evidence: `ds['a'].values.dtype == ds.stack(b=('a',))['a'].values.dtype`
should be `True` for `a` with dtype `i4`.

Semantic obligation: default `.values` materialization for a stacked level
coordinate must expose the same dtype as the original coordinate.

Status: encoded by `SPEC.md` B4; formalized by claim
`STACKED-LEVEL-VALUES-DTYPE`.

E3. Source: `benchmark/PROBLEM.md`

Quoted evidence: "Xarray array wrappers for pandas indexes keep track of the
original dtype and should restore it when converted into numpy arrays."

Semantic obligation: the adapter's stored dtype is the authoritative default
conversion dtype.

Status: encoded by `SPEC.md` B1 and B3; formalized by
`MI-ARRAY-DEFAULT-LEVEL-DTYPE`.

E4. Source: `repo/xarray/core/indexes.py`

Quoted evidence: `level_coords_dtype = {k: var.dtype for k, var in
variables.items()}` in `PandasMultiIndex.stack`.

Semantic obligation: stack records the original dtype for each level coordinate.

Status: implementation evidence for producer path; captured as proof obligation
`PO2`.

E5. Source: `repo/xarray/core/indexes.py`

Quoted evidence: `data = PandasMultiIndexingAdapter(self.index, dtype=dtype,
level=level)` in `PandasMultiIndex.create_variables`.

Semantic obligation: the recorded level dtype reaches the adapter that backs the
coordinate variable.

Status: implementation evidence for producer path; captured as proof obligation
`PO2`.

E6. Source: `repo/xarray/core/indexing.py`

Quoted evidence: `PandasIndexingAdapter.__array__` defaults `dtype` to
`self.dtype` before calling `np.asarray`.

Semantic obligation: the MultiIndex level adapter should follow the base
adapter's dtype-preserving conversion convention.

Status: encoded by `SPEC.md` B1 and B5; formalized by
`MI-ARRAY-DEFAULT-LEVEL-DTYPE` and `MI-ARRAY-NONLEVEL-DELEGATES`.

E7. Source: task instructions

Quoted evidence: "Do not modify any test files: the project's test suite is
fixed and hidden."

Semantic obligation: all changes must be limited to non-test source and
required reports/artifacts.

Status: encoded by `SPEC.md` B5 and `PUBLIC_COMPATIBILITY_AUDIT.md`.

