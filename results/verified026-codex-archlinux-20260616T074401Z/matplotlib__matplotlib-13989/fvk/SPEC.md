# FVK Spec

Status: constructed, not machine-checked.

## Unit under audit

`Axes.hist` in `repo/lib/matplotlib/axes/_axes.py`, lines around the
construction of `hist_kwargs`:

- `hist_kwargs = dict()`
- single/empty path: `hist_kwargs['range'] = bin_range`
- effective density: `density = bool(density) or bool(normed)`
- V1 behavior: `hist_kwargs['density'] = density` when `density and not stacked`
- call site: `np.histogram(x[i], bins, weights=w[i], **hist_kwargs)`

The observable modeled here is whether `range` and `density` are present in
the kwargs passed to `np.histogram`. This is the mechanism that determines
whether NumPy sees the requested bin range for automatic binning.

## Public intent ledger summary

- E-001/E-002/E-003: The issue requires
  `hist(..., bins='auto', range=(0, 1), density=True)` to return bins spanning
  `(0, 1)`, so the explicit range must reach the bin-edge computation.
- E-004: `density=False` already respects range, so that behavior is a frame
  condition.
- E-005/E-006/E-007: The docstring separates range selection from density
  normalization.
- E-008: `normed` is deprecated but still follows the effective-density branch.
- E-009: stacked density is normalized manually after raw histogram counts are
  computed, so stacked behavior is a frame condition.
- E-010/E-011: The source identifies `hist_kwargs` as the mechanism being
  verified.

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Abstract state

The mini-K model abstracts the relevant Python state to:

- `inputEmpty: Bool`
- `nx: Int`, the number of datasets after reshaping
- `range: range(lo, hi)`
- `densityArg: Bool`
- `normedArg: Bool`
- `stacked: Bool`
- output kwargs represented as `kw(hasRange, rangeValue, hasDensity, densityValue)`

This abstraction preserves the property under verification: whether the
provided range survives while density is added.

## Function contract

For all valid ranges `lo < hi`, if `Axes.hist` reaches the single-dataset or
empty-input kwargs path, effective density is true, and `stacked` is false, the
constructed kwargs must contain both:

- `range=(lo, hi)`
- `density=True`

For the prompt's concrete case, this means the later `np.histogram` call sees
`range=(0, 1)` while also receiving `density=True`; by NumPy's documented
histogram behavior for automatic bins, the returned edge array spans the
provided range.

## Frame contracts

- With effective density false on the single/empty path, the kwargs still
  contain `range=(lo, hi)` and do not contain `density`.
- With `stacked=True`, effective density does not add `density=True` to
  `np.histogram` kwargs, preserving manual stacked normalization later.
- With multiple non-empty datasets, range is consumed by
  `histogram_bin_edges(..., bin_range, ...)` before the per-dataset histogram
  loop. The later kwargs may omit `range`, but effective density is still
  added for non-stacked density histograms.
- `normed=True` follows the same effective-density behavior as `density=True`.

## Formal files

- `fvk/mini-hist-kwargs.k`: mini semantics for the kwargs construction.
- `fvk/hist-kwargs-spec.k`: reachability claims for the obligations above.

No loops occur in the modeled fragment, so no circularity claim is required.
