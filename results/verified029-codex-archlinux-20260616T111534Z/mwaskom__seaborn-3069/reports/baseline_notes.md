# Baseline Notes

## Root cause

The objects interface already infers or accepts `Nominal` scales for coordinate
variables and converts category values to integer positions, but the compiled
Matplotlib axes were left to normal autoscaling and theme grid behavior. As a
result, nominal coordinate axes got ordinary margins, retained grid lines from
styles such as `darkgrid`, and did not invert the y axis. The older categorical
plot code applies those categorical-axis drawing rules after plotting, but the
objects finalization step did not have equivalent handling.

## Changed files

- `repo/seaborn/_core/plot.py`: Imported `Nominal` so finalized coordinate axes
  can detect nominal scales. Added a small helper for counting categories from
  Matplotlib's categorical unit mapping, with a tick-count fallback matching the
  existing categorical plot approach. Updated `Plotter._finalize_figure` so
  nominal coordinate axes disable their grid, default to limits of `-.5` through
  `n - .5`, and invert nominal y axes. Explicit `Plot.limit(...)` values are
  still applied, with nominal y axes inverted afterward when necessary.

## Assumptions and alternatives considered

- I treated `Nominal` coordinate scales as the objects equivalent of seaborn's
  categorical axis, so the grid is disabled even when the active theme would
  normally draw one.
- I left semantic `Nominal` scales unchanged; the issue concerns axes, so only
  x/y coordinate scales should receive categorical-axis drawing behavior.
- I used finalization rather than scale setup because artists autoscale the axes
  during drawing. This matches the categorical plot code, which also corrects
  limits after plotting.
- I considered adding invisible artists or sticky edges, but the existing
  categorical implementation directly sets the axis limits from the category
  count. Matching that approach is smaller and keeps the behavior explicit.
- I used Matplotlib's categorical unit mapping when available so an existing
  target axis with prior categories can still determine the full category count.
  The fallback uses tick count, consistent with the categorical code path.
