# Baseline Notes

## Root cause

`AxesImage._make_image` rescales scalar image data into a small floating-point
range before resampling, then converts the rescaled `vmin` and `vmax` back into
data coordinates and temporarily applies them to the image norm. This avoids
minor interpolation and round-trip errors at the color limits.

For `LogNorm`, the lower limit must be strictly positive. The existing guard
only repaired the temporary lower limit when it became negative. With a very
large input range, such as data spanning from `-1` to `1e20`, the round trip can
also collapse a positive `vmin` to exactly zero. That zero then reaches the log
transform as `vmin`, producing a non-finite transformed limit and raising
`ValueError("Invalid vmin or vmax")`.

## Files changed

`repo/lib/matplotlib/image.py`

Changed the `LogNorm` resampling guard in `_ImageBase._make_image` to repair a
non-positive temporary lower limit, not just a negative one. The replacement
limit remains the existing dtype epsilon fallback, so the change preserves the
local behavior while covering zero, which is equally invalid for log
normalization.

## Assumptions and alternatives considered

I assumed the issue is in the image resampling limit adjustment, not in
`LogNorm` itself, because `LogNorm` correctly rejects zero and negative limits.
The failing stack trace shows the invalid limit is introduced immediately before
calling the norm inside `_make_image`.

I considered changing `LogNorm` or `LogTransform` to tolerate zero limits, but
that would weaken the domain checks for all log normalization users and hide
invalid caller input outside the image resampling path. I also considered
reworking the temporary range scaling to preserve small positive limits across
huge linear ranges, but that would be a larger numerical refactor. The targeted
fix matches the existing intent of the `LogNorm` special case and only extends
it from negative values to all non-positive values.

No tests or project code were run, per the task instructions.
