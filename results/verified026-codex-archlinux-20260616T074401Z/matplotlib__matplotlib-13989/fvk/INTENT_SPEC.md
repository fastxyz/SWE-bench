# Intent Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 change to `Axes.hist` in
`repo/lib/matplotlib/axes/_axes.py`, specifically the construction of keyword
arguments passed to `np.histogram` for the `range`, `density`, `normed`, and
`stacked` controls.

The proof does not model rendering, bar construction, autoscaling, unit
conversion, or NumPy's histogram implementation. Those are outside the
reported defect and remain integration behavior to test conventionally.

## Intent-only obligations

I-001: For a non-empty single dataset with a user-provided valid `range=(lo,
hi)`, `bins='auto'`, `density=True`, and `stacked=False`, the returned bin
edges must be computed over the user range. Therefore the histogram call path
must preserve the range value through to the bin-edge computation. For the
reported example `range=(0, 1)`, the first returned edge is `0` and the last
returned edge is `1`.

I-002: `density=True` changes count normalization only. It must not change
which bin range is used.

I-003: The behavior that already worked with `density=False` is a frame
condition: the range entry must remain present for the single-dataset
non-stacked path when density is false.

I-004: The deprecated `normed` parameter follows the same effective-density
branch as `density`, because the docstring states that if either `density` or
`normed` is set, that value is used.

I-005: Stacked density histograms remain a separate frame condition. The
existing implementation computes raw histograms first and manually normalizes
the stacked result later, so the fix must not pass `density=True` to
`np.histogram` on the stacked path.

I-006: For multiple non-empty datasets, the code computes common bin edges with
`histogram_bin_edges(..., bin_range, ...)` before the per-dataset histogram
loop. The `range` kwarg therefore need not be present in the later
`np.histogram` kwargs for that path, but effective density still must be passed
when `stacked=False`.

## Domain assumptions

D-001: The formal claims use boolean-normalized `density` and `normed`
arguments. This matches the audited code after `bool(density) or bool(normed)`.

D-002: A "valid range" is modeled as `lo < hi`. The issue's concrete
`range=(0, 1)` is in this domain.

D-003: `input_empty=False` and `nx=1` model the issue's non-empty single
dataset. Additional frame claims cover the empty/single and multiple-dataset
branch distinction at the kwargs-routing level.
