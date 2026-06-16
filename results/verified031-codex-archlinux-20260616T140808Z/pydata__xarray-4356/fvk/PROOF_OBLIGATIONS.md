# FVK Proof Obligations

Status: constructed, not machine-checked. These obligations are derived from the
public intent ledger in `fvk/SPEC.md` and the findings in `fvk/FINDINGS.md`.

## PO-001: Public multi-dimension input reaches `_maybe_null_out`

- Statement: for `DataArray.sum(dim=[d0, d1], min_count=m)` on floating data,
  xarray maps the dimension list to an axis tuple and dispatches to
  `nanops.nansum`, which calls `_maybe_null_out` when `min_count` is not `None`.
- Evidence: E-001, E-002, E-005.
- Discharge: source inspection shows `get_axis_num` returns a tuple for iterable
  dimensions and `nansum` calls `_maybe_null_out(result, axis, mask, min_count)`.
- Status: discharged by construction.

## PO-002: Reduced element count for several axes is the product of their sizes

- Statement: for an array-valued reduction over axes `A`, the total candidate
  count for each output position is `product(mask.shape[a] for a in A)`.
- Evidence: E-003.
- Discharge: V1 computes `np.take(mask.shape, axis).prod()`, which selects the
  shape entries for all reduced axes and multiplies them.
- Status: discharged by construction.

## PO-003: `min_count` null decision is equivalent to valid-count comparison

- Statement: for each output position, `result` is NA iff
  `product(reduced_axis_sizes) - missing_count < min_count`.
- Evidence: E-004.
- Discharge: V1 computes `(count - mask.sum(axis) - min_count) < 0`, equivalent
  to `count - mask.sum(axis) < min_count`.
- K claims: MULTI-AXIS-NULL and MULTI-AXIS-KEEP in
  `fvk/nanops-min-count-spec.k`.
- Status: discharged by construction.

## PO-004: Single-axis behavior is preserved

- Statement: when `axis` is one integer, the V1 formula produces the same
  `count` as the pre-existing intended one-axis formula.
- Evidence: E-006.
- Discharge: `np.take(mask.shape, axis).prod()` with one integer axis is equal to
  `mask.shape[axis]`; the null decision formula is otherwise unchanged.
- K claims: SINGLE-AXIS-NULL and SINGLE-AXIS-KEEP in
  `fvk/nanops-min-count-spec.k`.
- Status: discharged by construction.

## PO-005: Scalar/all-dimension branch is preserved

- Statement: reductions that produce scalar-like results continue to use
  `mask.size - mask.sum()` and are unaffected by the array-valued axis product
  change.
- Evidence: E-006 and V1 source.
- Discharge: V1 edited only the `axis is not None and result.ndim` branch; the
  `elif getattr(result, "dtype", None) not in dtypes.NAT_TYPES` branch remains
  unchanged.
- Status: discharged by construction.

## PO-006: Public compatibility is preserved

- Statement: the fix must not require callers, overrides, or public API users to
  change signatures or call forms.
- Evidence: E-002 and compatibility audit in `fvk/SPEC.md`.
- Discharge: no public signature changed; `_maybe_null_out` remains private with
  the same parameters.
- Status: discharged by construction.

## PO-007: Proof honesty and residual testing

- Statement: because the formal model abstracts away full NumPy/Dask semantics,
  the proof cannot justify deleting tests or claiming machine-checked confidence.
- Evidence: F-004.
- Discharge: artifacts are labeled constructed, not machine-checked, and the
  guidance keeps tests.
- Status: acknowledged proof-scope limitation.

