# Public Evidence Ledger

Status: constructed from allowed local files only.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`to_unstacked_dataset broken for single-dim variables`" | Single-dimensional variables are in the intended domain. | Encoded in SPEC and PO3. |
| E2 | `benchmark/PROBLEM.md` | MCVE ends in `MergeError: conflicting values for variable 'y'` | The stacked coordinate metadata must not be merged as conflicting output coordinates. | Encoded in PO3 and repaired. |
| E3 | `benchmark/PROBLEM.md` | "Expected Output: A working roundtrip." | `to_stacked_array(...).to_unstacked_dataset(...)` should reconstruct the original dataset for the issue family. | Encoded in PO2-PO6. |
| E4 | `repo/xarray/core/dataarray.py` docstring | "This is the inverse operation of Dataset.to_stacked_array." | Output variable shapes and coordinates should match the producer's original variables for covered roundtrip cases. | Encoded in PO4-PO6. |
| E5 | `repo/xarray/core/dataset.py` docstring | "`sample_dims`: Dimensions that will not be stacked" | Sample dimensions are frame conditions and should survive unstacking. | Encoded in PO4; V1 violated this for length-one sample dimensions. |
| E6 | `repo/xarray/tests/test_dataset.py` | Existing roundtrip tests for same-dimensional and mixed-dimensional variables. | Preserve existing behavior for variables that retain a real stacked level and for variables missing one. | Encoded in PO5-PO6. |
| E7 | `repo/xarray/tests/test_dataarray.py` | Existing non-MultiIndex error test. | Keep the `ValueError` behavior for non-stacked coordinates. | Encoded in PO1. |
| E8 | V1 implementation | `.squeeze(drop=True)` without a `dim` argument. | Implementation-derived behavior: all length-one dimensions are removed. | Finding F2; rejected as inconsistent with E4-E5. |
