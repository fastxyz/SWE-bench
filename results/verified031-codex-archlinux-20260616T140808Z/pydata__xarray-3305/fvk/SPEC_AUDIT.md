# Spec Audit

Status: adequacy gate passed for the attrs-preservation contract.

| Formal claim | Intent coverage | Verdict |
| --- | --- | --- |
| VQ-KEEP-TRUE | E5 requires `Variable.quantile` to have `keep_attrs`; E1/E2 require preserving attrs for the reported `DataArray` path, which depends on variable attrs. | Pass |
| VQ-KEEP-FALSE | Existing `keep_attrs` convention says false/default drops attrs; E7 confirms default false behavior. | Pass |
| VQ-KEEP-DEFAULT-* | E7 gives `_get_keep_attrs(default=False)` as the existing option resolution. | Pass |
| DATASET-PASS-KEEP | E4 identifies the temp dataset path; E8 shows the local reduction pattern of resolving and passing `keep_attrs` to variables. | Pass |
| DATASET-PASS-DROP | Existing false behavior remains required by the keep_attrs contract. | Pass |
| DA-KEEP-TRUE | Directly matches E1/E2 expected output. | Pass |
| DA-KEEP-FALSE | Prevents overfitting the fix into unconditional attr copying; supported by keep_attrs semantics in E7. | Pass |
| Numeric value/dim frame | Numeric correctness is not newly specified by this issue and is delegated to the existing `np.nanpercentile` path. The abstraction preserves a distinct attrs axis, so it is not vacuous for the reported defect. | Pass with scope note |
| Docstring correction | E10 shows V1 documentation mismatch; changing "dataset's" to "array's" aligns docs with E1/E2/E6. | Pass |

No claim relies on hidden tests, candidate-only behavior, or the pre-fix
`OrderedDict()` output. The pre-fix empty attrs result is explicitly marked as
SUSPECT legacy behavior in the ledger.
