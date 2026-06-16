# Baseline Notes

## Root cause

`Colorbar._add_solids` builds the divider `LineCollection` from the mesh
coordinates for the main colorbar body.  The previous code always used
`np.dstack([X, Y])[1:-1]`, which drops both end boundary segments.

Dropping both ends is correct for a colorbar without extensions because the
outline spine draws those outer edges.  It is not correct when `extend` includes
`'min'`, `'max'`, or `'both'`: the outline for triangular or rectangular
extensions follows the outside of the extension patch and does not draw the
join line between the extension and the main colorbar body.  As a result,
`drawedges=True` omitted the divider at each extended extremity.

## Files changed

- `repo/lib/matplotlib/colorbar.py`
  - Changed `Colorbar._add_solids` so the divider segments keep the first
    mesh boundary when `extend` includes the minimum side and keep the last
    mesh boundary when `extend` includes the maximum side.
  - Kept the old behavior for non-extended sides, where the outline already
    supplies the visible boundary.

## Assumptions and alternatives considered

- I treated `extend='min'` and `extend='max'` as data-side choices, so the
  first and last mesh boundaries are selected from `self.extend` directly.
  This keeps the divider at the boundary between the under/over extension
  color and the corresponding end of the main colorbar.
- I considered modifying `_do_extends` to add lines to the extension patches,
  but that would duplicate line styling and patch geometry logic.  The missing
  artists are divider segments, so fixing the divider segment selection is the
  narrower change.
- I did not change tests or run the test suite, per the task constraints.
