# FVK Findings

Status: constructed, not machine-checked. No runtime or K commands were run.

## F-001: Pre-V1 multi-axis `min_count` rejection was the operative bug

- Classification: code bug, resolved by V1.
- Evidence: E-001 and E-002 in `fvk/SPEC.md`.
- Input: `xr.DataArray([[1., 2, 3], [4, 5, 6]]).sum(["dim_0", "dim_1"], min_count=1)`.
- Observed before V1: `_maybe_null_out` raised
  `ValueError("min_count is not available for reduction with more than one dimensions.")`
  for tuple/list axes.
- Expected: the reduction completes and applies the ordinary `min_count`
  predicate over all reduced elements.
- Related proof obligations: PO-001, PO-002, PO-003.
- V1 status: resolved by removing the tuple/list rejection and computing the
  reduced element count as the product of reduced axis sizes.

## F-002: Multi-axis valid-count arithmetic is the critical correctness point

- Classification: proof obligation, discharged by construction.
- Evidence: E-003 and E-004 in `fvk/SPEC.md`.
- Input class: array-valued reductions with shape dimensions `D0, D1, ...`,
  tuple axis `(a0, a1, ...)`, `NULLS` missing values in an output slice, and
  nonnegative `min_count`.
- Expected: `valid_count = product(reduced_axis_sizes) - NULLS`; result is NA iff
  `valid_count < min_count`.
- V1 behavior by source inspection: `count = np.take(mask.shape, axis).prod()`
  and `null_mask = (count - mask.sum(axis) - min_count) < 0`.
- Related proof obligations: PO-002 and PO-003.
- Status: no source change beyond V1 is justified.

## F-003: Single-axis and scalar/all-dimension behavior must be preserved

- Classification: regression risk, discharged by construction for the helper.
- Evidence: E-006 in `fvk/SPEC.md`.
- Input class: existing `min_count` reductions over one axis, and reductions
  that produce a scalar.
- Expected: one-axis behavior remains equivalent to `mask.shape[axis]`; scalar
  and all-dimension reductions continue to use `mask.size - mask.sum()`.
- V1 behavior by source inspection: `np.take(mask.shape, axis).prod()` equals
  `mask.shape[axis]` for a single integer axis, and the scalar/all-dimension
  branch was left unchanged.
- Related proof obligations: PO-004 and PO-005.
- Status: no further code change is justified.

## F-004: Full NumPy/Dask semantics are outside the mini-proof

- Classification: proof capability gap / escalation boundary, not a code bug.
- Evidence: the FVK docs describe mini-language semantics as an MVP stopgap.
- Scope limit: the proof models the arithmetic decision in `_maybe_null_out`;
  it does not machine-check real NumPy tuple-axis reductions, Dask graph
  behavior, dtype promotion, or lazy evaluation.
- Related proof obligations: PO-007.
- Recommendation: keep ordinary tests. Add or retain tests for multi-axis
  `sum(..., min_count=...)`, including a not-enough-valid-values case and a
  single-axis regression case. Test removal is not recommended without a real
  K/NumPy/Dask semantics and successful `kprove`.

