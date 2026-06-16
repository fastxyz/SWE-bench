# FVK Spec: pydata__xarray-4356

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

Target behavior is the `sum(..., min_count=...)` path for floating/nan-aware
reductions when the caller supplies more than one dimension. The source units in
scope are:

- `DataArray.reduce` / `Variable.reduce`, which map a dimension sequence to an
  axis tuple before calling the reducer.
- `duck_array_ops.sum`, which dispatches floating data with `skipna=None` or
  `skipna=True` to `nanops.nansum`.
- `nanops.nansum` and `_maybe_null_out`, which apply `min_count`.

`nanops.nanprod` uses the same helper. The proof obligations therefore preserve
the helper's generic behavior, but the public issue obligation is for `sum`.

## Intent-Only Spec

1. A floating `DataArray.sum` call with `min_count` and a sequence of dimensions
   is in-domain and must not fail merely because several dimensions are reduced.
2. For every output position of an array-valued reduction, the result is NA iff
   the number of non-NA values across all reduced axes is less than `min_count`.
3. For a multi-axis reduction, the number of elements being reduced for each
   output position is the product of the sizes of all reduced axes.
4. Single-axis and scalar/all-dimension `min_count` behavior must remain
   equivalent to the pre-existing intended behavior.
5. The public API and call signatures must remain compatible.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt | `sum: min_count is not available for reduction with more than one dimensions` | Multi-dimension `sum` with `min_count` is a supported in-domain case; the previous error is the bug. | Encoded in PO-001 and PO-002. |
| E-002 | prompt | `da.sum(["dim_0", "dim_1"], min_count=1)` | A list of dimensions is a public input form. | Encoded in PO-001 and compatibility audit. |
| E-003 | prompt | Replace `mask.shape[axis]` with `np.take(a.shape, axis).prod()` | Reduced element count for several axes is the product of those axis sizes. | Encoded in PO-002. |
| E-004 | docs | `If fewer than min_count non-NA values are present the result will be NA` | Null decision is `valid_count < min_count`. | Encoded in PO-003. |
| E-005 | code | `get_axis_num` returns a tuple for iterable dimensions. | The issue input reaches `nanops` as a tuple axis, not as separate reducer calls. | Used as implementation evidence for PO-001. |
| E-006 | public tests | Existing public tests cover `min_count` for `sum`/`prod` on `dim=None` and one named dim, and multi-dim reductions without `min_count`. | The fix must not regress single-axis or scalar/all-axis behavior; multi-axis `min_count` is the uncovered cross-product. | Encoded in PO-004 and guidance. |

## Formal Model

The target code has no loops, so there are no loop circularities. The formal core
is a reduced mini semantics of the `_maybe_null_out` decision for one output
position after the reduction result exists:

```text
total = product(shape[axis_i] for axis_i in reduced_axes)
nulls = number of NA values reduced into this output position
valid = total - nulls
decision = null iff valid < min_count, else keep
```

This abstraction is property-complete for the defect because it preserves the
axis that distinguishes pass from fail: `total` is single-axis size in the old
case and product-of-axis-sizes in the fixed multi-axis case. It intentionally
does not model full NumPy, pandas, Dask, dtype promotion, or xarray indexing.
Those are outside the bundled FVK tier and remain covered by ordinary tests.

Supporting formal files:

- `fvk/mini-nanops.k`
- `fvk/nanops-min-count-spec.k`

## Formal Spec English

- MULTI-AXIS-NULL: for positive axis lengths `D0` and `D1`, nonnegative
  `NULLS`, and nonnegative `MIN`, `maybeNull(D0 * D1, NULLS, MIN)` returns
  `null` when `D0 * D1 - NULLS < MIN`.
- MULTI-AXIS-KEEP: under the same domain, it returns `keep` when
  `D0 * D1 - NULLS >= MIN`.
- SINGLE-AXIS-NULL: for positive single-axis length `D0`, it returns `null`
  when `D0 - NULLS < MIN`.
- SINGLE-AXIS-KEEP: for positive single-axis length `D0`, it returns `keep`
  when `D0 - NULLS >= MIN`.

## Adequacy Audit

| Formal obligation | Intent match | Result |
| --- | --- | --- |
| Multi-axis decision uses `D0 * D1` | Matches E-001, E-003, and E-004. | Pass |
| Null iff valid count is less than `min_count` | Matches E-004. | Pass |
| Single-axis decision still uses `D0` | Matches preservation obligation E-006 and follows from `np.take(shape, axis).prod()` for an integer axis. | Pass |
| Full Python/NumPy/Dask execution semantics | Not fully modeled by the mini semantics. This does not block the source decision, but it blocks test-removal confidence. | Proof-scope limitation |

## Public Compatibility Audit

- No public method signature changed.
- `_maybe_null_out` remains private and keeps the same parameters.
- The existing public input form `dim=["dim_0", "dim_1"]` continues through
  `get_axis_num` as an axis tuple; V1 removes only the helper's rejection of that
  tuple.
- No subclass override or virtual dispatch shape is changed.

