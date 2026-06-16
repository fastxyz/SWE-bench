# Baseline Notes

## Root cause

`HPacker` delegates vertical child alignment to `_get_aligned_offsets()`, passing
each child as a `(height, ydescent)` pair. That helper returns bottom offsets for
the children. For bottom alignment, the bottom offset should be the child's
descent (`d`), which places every child on the bottom edge of the packing box.
For top alignment, the bottom offset should be `height - h + d`, which moves
shorter children upward so their top edges match the tallest child or requested
container height.

The existing implementation grouped `top` with `left` and `bottom` with
`right`. That grouping is correct for `left` and `right` when the same helper is
used by `VPacker` for horizontal alignment, but it reverses the vertical meaning
of `top` and `bottom` for `HPacker`.

## Files changed

- `repo/lib/matplotlib/offsetbox.py`: swapped the `top` and `bottom` entries in
  `_get_aligned_offsets()` so `bottom` uses the zero-edge offset branch and
  `top` uses the far-edge offset branch. This preserves the existing `left` and
  `right` behavior used by `VPacker` while fixing the inverted `HPacker`
  vertical alignment.

## Assumptions and alternatives considered

- I treated the behavior as a plain bugfix, matching the issue discussion that
  `HPacker(align="bottom")` should align child bottoms and `align="top"` should
  align child tops.
- I considered adding a compatibility flag or accepting temporary uppercase
  alignment values, as mentioned in the public hints, but rejected that as
  broader API work than needed for the requested fix and inconsistent with the
  minimal source-only change expected here.
- I did not change tests or run code, because the task explicitly forbids both.
