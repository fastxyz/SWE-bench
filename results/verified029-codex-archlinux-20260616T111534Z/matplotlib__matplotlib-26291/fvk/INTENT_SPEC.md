# Intent Specification

This file records intent before accepting candidate behavior as correct.

## Required Behaviors

1. `mpl_toolkits.axes_grid1.inset_locator.inset_axes` should create an inset
   axes that can be displayed in the documented usage pattern from the issue.
2. The tight-bbox / inline-backend rendering path may call the inset axes
   locator as `locator(ax, None)`.
3. That `None` renderer call must not raise an `AttributeError` because the
   locator itself lacks a `figure` attribute.
4. The locator should use the axes' figure to obtain a renderer when no renderer
   was supplied by the caller.
5. Existing behavior with an explicitly supplied renderer should be preserved.
6. The fix should not change public function signatures, return types, or
   documented inset axes arguments.

## Domain Assumptions

- `ax` is a normal Matplotlib axes associated with a figure.
- `ax.figure._get_renderer()` is the standard Matplotlib fallback for omitted
  renderers, matching the pattern used by `Axes.get_tightbbox`.
- Invalid axes objects and renderer construction failures are outside this
  issue's public intent.
