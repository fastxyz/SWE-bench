# Formal Spec in English

Status: constructed, not machine-checked.

This file paraphrases each nontrivial K claim in
`fvk/hist-kwargs-spec.k`.

## Claim `hist-range-density`

For any valid range `range(lo, hi)` with `lo < hi`, a non-empty single-dataset
histogram with `density=True`, `normed=False`, and `stacked=False` constructs
kwargs containing the same range and containing `density=True`.

## Claim `hist-range-normed`

For any valid range `range(lo, hi)` with `lo < hi`, a non-empty single-dataset
histogram with `normed=True`, `density=False`, and `stacked=False` constructs
kwargs containing the same range and containing `density=True`.

## Claim `hist-range-no-density`

For any valid range `range(lo, hi)` with `lo < hi`, a non-empty single-dataset
histogram with both `density=False` and `normed=False` constructs kwargs
containing the same range and no `density` entry.

## Claim `hist-stacked-frame`

For any valid range `range(lo, hi)` with `lo < hi`, a non-empty single-dataset
stacked histogram with effective density true constructs kwargs containing the
same range but no `density=True` entry. This leaves stacked density
normalization to the later manual normalization block.

## Claim `hist-multi-density-frame`

For two non-empty datasets with a valid range and `density=True`,
`stacked=False`, the modeled per-dataset `np.histogram` kwargs omit `range`
because common bins were already computed using `histogram_bin_edges`, but they
do include `density=True`.
