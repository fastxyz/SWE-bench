# FVK Iteration Guidance

Status: V1 confirmed; no further source edits required.

## Decision

Keep V1 unchanged.

The audit found that the existing patch discharges the DataArray normalization
obligation before all mapping-specific operations. It also preserves non-
DataArray behavior and top-level DataArray conversion errors.

## Guidance for Future Work

- Add a regression test for `Dataset.merge(named_dataarray)` comparing against
  `xr.merge([dataset, dataarray])`.
- Add a regression test for `overwrite_vars` with a named `DataArray`, because
  the method has compatibility-specific branching not present in top-level
  `merge()`.
- Add a regression test for an unnamed `DataArray` to ensure the method raises
  the same conversion error as top-level `merge()`.
- Keep existing Dataset/mapping merge tests; the constructed proof was not
  machine-checked and does not justify test deletion.

## Residual Risk

- The proof abstracts `merge_core()` as a downstream consumer that requires
  Dataset/mapping-like objects. That is sufficient for the reported failure,
  but it does not prove all of xarray's merge semantics.
- No Python, tests, `kompile`, or `kprove` were run, per task instructions.
- The formal proof is partial over the helper's source-level control flow. It
  does not make claims about performance or all possible invalid input types.
