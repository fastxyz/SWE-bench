# Baseline Notes

## Root Cause

`combine_by_coords` correctly ignores coordinate dimensions whose indexes are
identical across all datasets when it infers `concat_dims` in
`_infer_concat_order_from_coords`. However, after concatenating each group of
datasets, it checked monotonicity for every dimension coordinate in the
combined result. That second check included bystander coordinate dimensions
that were intentionally excluded from concatenation, so identical non-monotonic
coordinates could still raise `ValueError`.

The issue example has varying `x` coordinates and identical `y` coordinates.
`y` is not a concat dimension, but the final all-dimension monotonicity check
still inspected `y` and rejected the result.

## Changed Files

`repo/xarray/core/combine.py`

Scoped the final global index monotonicity check in `combine_by_coords` to
`concat_dims` instead of all dimensions in the concatenated dataset. This keeps
the existing validation for dimensions that were actually concatenated and
ordered by coordinate values, while allowing identical bystander coordinates to
be non-monotonic as documented.

## Assumptions and Alternatives

I assumed the documented statement that coordinate dimensions which do not vary
between datasets are ignored applies both during concat-order inference and
during post-concatenation validation.

I considered removing the final monotonicity check entirely, but rejected that
because it still catches impossible inferred orderings along real concat
dimensions, such as a global `x` index that becomes non-monotonic after
combination.

I considered detecting non-varying dimensions again after concatenation, but
rejected that as unnecessary because `_infer_concat_order_from_coords` already
produces the exact list of dimensions selected for concatenation. Reusing
`concat_dims` is the smallest change and matches the existing implementation
structure.

No tests were run, per the task instructions.
