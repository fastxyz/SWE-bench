# FVK Notes

## Decisions

The V1 core design stands: `SelectorMixin` should preserve pandas dtypes by selecting columns from the original `DataFrame` after validation when pandas output is configured. This is justified by `fvk/FINDINGS.md` F1 and the proof obligations `PO-VALIDATE-FIRST`, `PO-DF-DTYPE-PRESERVE`, `PO-DEFAULT-UNCHANGED`, and `PO-SCOPE-LIMIT`. The formal intent in `fvk/INTENT_SPEC.md` limits the behavior to selectors and rejects generic cast-back for computed transformers.

I made one V2 source refinement in `repo/sklearn/feature_selection/_base.py`. V1 queried `_get_output_config` at the start of raw `transform`; `fvk/FINDINGS.md` F2 identified that as an avoidable compatibility risk because invalid output config could be raised before validation. The V2 helper `_is_pandas_output_configured` is called only after `_validate_data` succeeds and treats invalid config as not pandas-preserving, leaving the existing wrapper path to report invalid config when raw transform otherwise succeeds. This discharges `PO-INVALID-CONFIG-ORDER`.

I kept the `_safe_indexing` change in `_transform`. It discharges `PO-DF-DTYPE-PRESERVE` for the pandas path while preserving dense and sparse selected-column behavior under `PO-ARRAY-SPARSE-UNCHANGED`. The empty-selection DataFrame branch is retained because `fvk/FINDINGS.md` F4 and `PO-EMPTY-PANDAS` require avoiding scalar `X.dtype` access on a DataFrame.

I did not change `_SetOutputMixin` or `_wrap_in_pandas_container`. `fvk/FINDINGS.md` F3 and `PO-SCOPE-LIMIT` reject a global dtype cast-back because it would misrepresent transformers that compute new values.

## Verification Status

The FVK proof is constructed, not machine-checked. I did not run tests, Python, `kompile`, `kast`, or `kprove`, per the task constraints. The exact commands to run later are recorded in `fvk/SPEC.md` and `fvk/PROOF.md`.
