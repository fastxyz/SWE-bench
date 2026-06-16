# Baseline Notes

## Root cause

`SpanSelector` creates its internal span patch at `(0, 0)` with one data
coordinate dimension and one axes-coordinate dimension. The patch was added via
`Axes.add_patch`, which updates the axes data limits even though the patch is an
invisible widget helper. In interactive mode, `SpanSelector` also initializes
edge handles at the current span extents, initially `(0, 0)`. Those handles were
created with `Axes.axvline` or `Axes.axhline`, which both add the line to the
axes data limits and may request autoscaling when the handle position falls
outside the current view. As a result, constructing an interactive horizontal
`SpanSelector` could put `x=0` into `dataLim`, so the next autoscale/draw expanded
the x limits to include zero before any user selection occurred.

## Changed files

`repo/lib/matplotlib/widgets.py`

- `SpanSelector.new_axes` now attaches the internal rectangle with
  `Axes.add_artist` instead of `Axes.add_patch`. This keeps the patch drawable
  and removable, but avoids treating the invisible selector helper as plotted
  data for autoscaling.
- `ToolLineHandles.__init__` now constructs the vertical or horizontal
  `Line2D` handle artists directly with the same blended x-axis or y-axis
  transforms and adds them with `Axes.add_artist`. This preserves the existing
  handle geometry and `set_data` behavior while avoiding the autoscale side
  effects of `axvline` and `axhline`.

## Assumptions and alternatives considered

I assumed selector helper artists should not affect axes limits at construction
or during interaction; their role is UI feedback, not plotted data. This matches
the expected behavior in the issue: creating the widget should leave limits from
the plotted data unchanged.

I considered restoring `dataLim` after adding the patch and handles, but rejected
that because it would be more fragile around lazy autoscaling and shared axes.
I also considered changing the initial extents away from zero, but that would
only hide this particular reproduction and still leave widget artists coupled to
autoscaling. Adding the artists through `add_artist` is narrower and directly
matches Matplotlib's existing API distinction for artists that should not be
included in automatic data-limit updates.

Tests were not run because the task instructions explicitly prohibit running
tests or code in this environment.
