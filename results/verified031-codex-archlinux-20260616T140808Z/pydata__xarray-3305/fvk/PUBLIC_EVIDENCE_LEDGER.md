# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt/problem | "DataArray.quantile does not honor `keep_attrs`" | `DataArray.quantile` must honor the `keep_attrs` parameter. | Encoded in SPEC and K claims DA-KEEP-TRUE / DA-KEEP-FALSE. |
| E2 | prompt/problem | MCVE constructs `xr.DataArray(..., attrs={'units':'K'})`, calls `quantile(..., keep_attrs=True)`, and expects `OrderedDict([('units', 'K')])`. | When `keep_attrs=True`, returned `DataArray.attrs` equals original attrs. | Encoded as primary postcondition. |
| E3 | prompt/problem | Current output is `OrderedDict()` and is presented as the bug. | Empty attrs on the reported input is SUSPECT legacy behavior, not the spec. | Recorded as closed Finding F1. |
| E4 | prompt/hint | "`DataArray.quantile` method creates a temporary dataset, copies the variable over..." | The temp-dataset route is implementation evidence to model: attrs live on the variable, not on the temporary dataset. | Encoded in SPEC and mini semantics. |
| E5 | prompt/hint | "Variable.quantile should have a `keep_attrs` argument, correct? Yes..." | `Variable.quantile` should expose and implement `keep_attrs`. | Encoded in VQ-KEEP-TRUE / VQ-KEEP-FALSE. |
| E6 | source/docstring | `DataArray.attrs` returns `self.variable.attrs`. | `DataArray` attrs preservation is variable attrs preservation. | Encoded in SPEC. |
| E7 | source/options | `_get_keep_attrs(default=False)` resolves `None` using global option or default. | `keep_attrs=None` in quantile should use the same default/global behavior as reductions. | Encoded in VQ-KEEP-DEFAULT and DATASET-PASS-DEFAULT. |
| E8 | source/reduce pattern | `Dataset.reduce` resolves `keep_attrs` before iterating variables and passes it into `var.reduce(...)`. | `Dataset.quantile` should resolve once and pass the same value to variable quantile. | Encoded in DATASET-PASS-KEEP. |
| E9 | source/callsites | `GroupBy.quantile` forwards `keep_attrs` to `DataArray`/`Dataset.quantile`; direct `Variable.quantile` callers use existing args. | Adding an optional trailing argument to `Variable.quantile` should be backward compatible. | Encoded in PUBLIC_COMPATIBILITY_AUDIT. |
| E10 | source/docstring | V1 left `DataArray.quantile` docstring saying "dataset's attributes" for `keep_attrs`. | The public docs should describe array attrs for `DataArray.quantile`. | Fixed by V2 docstring change; Finding F3. |
