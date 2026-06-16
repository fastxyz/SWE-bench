# Proof Obligations

Status: constructed, not machine-checked. Obligation IDs are referenced by
`fvk/FINDINGS.md`, `fvk/PROOF.md`, and `reports/fvk_notes.md`.

## Attr preservation

- PO-1: `Variable.quantile(..., keep_attrs=True)` returns a new `Variable`
  whose attrs equal the input variable attrs.
- PO-2: `Variable.quantile(..., keep_attrs=False)` returns a new `Variable`
  with empty attrs.
- PO-3: `Variable.quantile(..., keep_attrs=None)` resolves through
  `_get_keep_attrs(default=False)` and then satisfies PO-1 or PO-2.
- PO-4: `Dataset.quantile` resolves `keep_attrs` before reducing variables and
  passes the resolved value into `var.quantile(...)`.
- PO-5: `Dataset.quantile` preserves dataset-level attrs exactly when the
  resolved keep flag is true, preserving existing dataset behavior.
- PO-6: `DataArray.quantile` preserves attrs when `keep_attrs=True` because the
  temporary dataset's reduced variable preserves attrs and `_from_temp_dataset`
  returns that variable as the result data array.
- PO-7: `DataArray.quantile` drops attrs when the resolved keep flag is false;
  the fix must not copy attrs unconditionally.

## Frame and error behavior

- PO-8: Numeric quantile values and dimension changes remain the existing
  `np.nanpercentile`/dimension logic. The attrs proof may abstract those as
  `quantileData` and `quantileDims` but must not alter source code on those
  axes.
- PO-9: Existing out-of-domain behavior remains unchanged: dask-backed variables
  still raise before result construction, invalid dimensions still fail through
  the existing validation, and unsupported data remains outside the proof
  domain.

## Compatibility and documentation

- PO-10: Adding `keep_attrs=None` to `Variable.quantile` is backward compatible
  because it is a trailing optional parameter and no public override rejects it.
- PO-11: Internal dispatch from `Dataset.quantile` to `var.quantile` is
  compatible with xarray `Variable`/`IndexVariable` objects.
- PO-12: Public documentation for `DataArray.quantile(keep_attrs=...)` should
  describe array attrs, not dataset attrs.
