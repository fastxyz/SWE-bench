# Baseline Notes

## Root cause

`Axes.bar` calls `Axes._convert_dx` to convert the bar width against the
original x data and the already-converted x data. That helper now asks
`cbook._safe_first_finite` for a representative x value so that a leading
`NaN` does not poison conversion when later finite values exist.

For all-`NaN` x data, however, `_safe_first_finite` raises `StopIteration`
because there is no finite element. `_convert_dx` did not handle that
exception, so `ax.bar([np.nan], [np.nan])` failed before it could create the
rectangle. This was specific to the x-position conversion path; a `NaN` height
still worked because the default baseline supplies a finite y reference.

## Changed files

`repo/lib/matplotlib/axes/_axes.py`

Handled `StopIteration` from `_safe_first_finite` inside `_convert_dx`. When no
finite representative exists, the conversion now falls back to
`cbook.safe_first_element`, preserving the previous all-nonfinite behavior while
keeping the intended first-finite behavior for mixed data such as a leading
`NaN` followed by finite values.

## Assumptions and alternatives considered

I assumed the correct behavior is to allow all-nonfinite bar coordinates to
create artists with nonfinite geometry, matching the issue's description of the
3.6.0 behavior and seaborn's phantom-bar use case.

I considered changing `cbook._safe_first_finite` to return the first element
when no finite element exists, but rejected that because other callers already
treat `StopIteration` as meaningful and broadening the helper behavior would
change more code paths than the issue requires.

I also considered letting `_convert_dx` fall back to `convert(dx)` by catching
`StopIteration` in the outer conversion block, but that would not preserve the
old behavior for all-nonfinite unit-aware positions. Falling back to the first
unfiltered element keeps unit conversion localized to the same path that handles
finite data.
