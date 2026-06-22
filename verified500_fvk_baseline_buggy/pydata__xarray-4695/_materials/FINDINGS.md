# FVK Findings

Status: constructed, not machine-checked.

## FVK-F1 - DataArray.loc Keyword Collision

- Classification: code bug, fixed.
- Evidence: E1, E2, E4.
- Input: `DataArray(..., dims=["dim1", "method"]).loc[dict(dim1="x", method="a")]`.
- Pre-fix observed behavior: the mapping was unpacked as
  `self.data_array.sel(dim1="x", method="a")`; `"a"` became the reserved
  inexact-match `method` option, leading to `ValueError: Invalid fill method`.
- Expected behavior: `"method"` remains an indexer key, equivalent to
  `self.data_array.sel({"dim1": "x", "method": "a"})`.
- Source decision: V1 changed `repo/xarray/core/dataarray.py` to call
  `self.data_array.sel(key)`. V2 keeps that change.
- Proof obligations: `PO-1`, `PO-2`, `PO-3`, `PO-5`.

## FVK-F2 - Same Dynamic-Indexer Pattern Outside `.loc`

- Classification: code bug, fixed in V2.
- Evidence: E3, E7.
- Input: any internal dynamic selection helper that constructs
  `{dim: value}` where `dim == "method"`, for example a group or iteration
  dimension named `"method"`.
- Pre-V2 observed behavior by source inspection: the helper calls used
  `.sel(**{dim: value})`, so `dim == "method"` would bind the reserved
  `.sel(method=...)` option instead of an indexer.
- Expected behavior: dynamic dimension names remain indexer keys, equivalent to
  `.sel({dim: value})`.
- Source decision: V2 changed `repo/xarray/core/computation.py` and
  `repo/xarray/core/groupby.py` to pass the constructed mapping positionally.
- Proof obligations: `PO-1`, `PO-4`, `PO-5`, `PO-6`.

## FVK-F3 - Direct `.sel(method="a")` Remains Ambiguous by API

- Classification: no code change; documented public API boundary.
- Evidence: E7.
- Input: `da.sel(method="a")` when `da` has a dimension named `"method"`.
- Observed behavior by API signature: `method` is a reserved parameter for
  inexact matching.
- Expected behavior under this audit: no change. The unambiguous direct `.sel`
  spelling for a colliding dimension name is `da.sel({"method": "a"})`.
- Source decision: do not change `DataArray.sel` or `Dataset.sel` signatures.
- Proof obligations: `PO-5`, `PO-6`.

## FVK-F4 - Proof Honesty and Execution Boundary

- Classification: proof capability and environment boundary.
- Evidence: task instructions and FVK honesty gate.
- Input: any proposed test run, Python reproduction, `kompile`, or `kprove`.
- Observed constraint: no execution environment exists and the task forbids
  running tests, Python, or K tooling.
- Expected behavior: write commands into artifacts and reason about their
  expected result without executing them.
- Source decision: no tests or project code were run; no test files were edited.
- Proof obligations: `PO-8`.
