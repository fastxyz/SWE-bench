# FVK Notes

## Decision

V1 stands unchanged after the FVK audit.

## Trace To Findings And Proof Obligations

- Kept `_where_data_first` and the `apply_ufunc` argument order `x, y, cond`
  because FVK-F3 and PO-1 show value semantics are preserved, while PO-3 shows
  the reordered arguments are needed for `keep_attrs=True` to preserve attrs
  from the data arguments before the mask.
- Kept `_get_keep_attrs(default=True)` for `keep_attrs=None` because PO-5
  discharges the global-option behavior and FVK-F2 concludes the default
  preservation policy is supported by the issue's expected output and the
  `DataArray.where` workaround. The compatibility risk is mitigated by
  `keep_attrs=False` and `xr.set_options(keep_attrs=False)`, covered by PO-4.
- Did not broaden the patch into `DataArray.__eq__` or binary-operation attr
  behavior because FVK-F1 and PO-7 identify already-dropped comparison attrs as
  a separate public issue. `xr.where` cannot recover attrs from
  `xr.where(data == 1, 5, 0)` when `cond` already has no attrs and both choices
  are scalars.
- Did not alter dtype promotion because PO-8 keeps that behavior delegated to
  `duck_array_ops.where`, and the public issue describes the dtype point as
  likely outside the xarray wrapper.
- Did not make additional API edits because FVK-F4 and PO-6 found no public
  three-argument callsite or override break from adding the optional
  `keep_attrs` parameter.

## Artifacts Produced

The required FVK artifacts are in `fvk/SPEC.md`, `fvk/FINDINGS.md`,
`fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and
`fvk/ITERATION_GUIDANCE.md`.

Following the FVK documentation's non-negotiable artifact contract, I also
produced `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`,
`fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`,
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`, `fvk/mini-xarray-where.k`, and
`fvk/xarray-where-spec.k`.

No tests, Python, or K framework commands were run.
