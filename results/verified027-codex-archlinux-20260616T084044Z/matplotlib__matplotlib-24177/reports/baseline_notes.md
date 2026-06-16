# Baseline Notes

## Root cause

`Axes.hist(..., density=True, histtype="step")` creates a single `Polygon`
for the step outline. When that patch is added to an Axes,
`Axes._update_patch_limits` computes data limits by iterating the patch path
through `Path.iter_bezier()`.

`iter_bezier()` forwards to `Path.iter_segments()`, whose default
`simplify=None` allows path simplification when the path is long and made of
straight segments. For the histogram step polygon, simplification can drop
intermediate vertices, including the vertices that define the true density
maximum. The resulting `dataLim` is therefore too small, so autoscaling can
clip or under-scale the y-axis for step histograms. Bar histograms do not hit
this because each bin rectangle updates the limits independently.

## Changed files

- `repo/lib/matplotlib/axes/_base.py`

  Changed `_update_patch_limits` to call `p.iter_bezier(simplify=False)`.
  Data-limit calculation must use the original path geometry, not a visually
  simplified path. Passing `simplify=False` preserves the existing Bezier
  extrema handling while ensuring all straight-line vertices in a long step
  polygon contribute to autoscaling.

## Assumptions and rejected alternatives

- I assumed the correct limit for a patch is based on its full input geometry,
  not the renderer's simplified representation. This matches autoscaling
  expectations and the behavior of `Path.get_extents()`, which already avoids
  simplifying straight-line paths when computing extents.
- I considered changing `Axes.hist` to manually update limits for step
  histograms from the bin edges and density values, but rejected that because
  the failure is in generic patch limit handling and would leave other long
  straight `Polygon` or `PathPatch` artists with the same bug.
- I considered replacing the custom loop in `_update_patch_limits` with
  `Path.get_extents()`, but rejected that as a broader behavioral change.
  The existing loop accounts for Bezier extrema, and disabling simplification
  fixes the regression without changing the surrounding transform or curve
  handling.
- I did not run tests or project code because the benchmark instructions
  explicitly forbid execution in this session.
