# Baseline Notes

## Root cause

`mpl_toolkits.axes_grid1.inset_locator.inset_axes` installs an
`AnchoredSizeLocator` as the inset axes' axes locator. During tight-bbox
rendering, `matplotlib._tight_bbox.adjust_bbox` calls axes locators as
`locator(ax, None)`.

`AnchoredLocatorBase.__call__` forwarded that `None` renderer to
`OffsetBox.get_window_extent`. Since the locator is not added to the axes as a
normal artist, its `figure` attribute is not set, so `OffsetBox` could not fall
back to `self.figure._get_renderer()`. The same missing renderer would also
break later size/offset calculations that need renderer methods such as
`points_to_pixels`.

## Files changed

- `repo/lib/mpl_toolkits/axes_grid1/inset_locator.py`
  - In `AnchoredLocatorBase.__call__`, derive a renderer from `ax.figure` when
    the caller passes `renderer=None`. The locator is invoked with the target
    axes, and axes are always associated with a figure, so this keeps renderer
    lookup local to the call without making the locator pretend to be a normal
    figure-owned artist.

## Assumptions and alternatives considered

- I assumed the caller may legitimately pass `None` for the renderer because
  `adjust_bbox` does this while preparing `bbox_inches="tight"` output.
- I assumed `ax.figure._get_renderer()` is the appropriate fallback because
  `Axes.get_tightbbox` uses the same pattern when its renderer argument is
  omitted.
- I considered setting `axes_locator.figure` when creating inset axes, but
  rejected it because the locator is not drawn or managed as a regular artist,
  and doing so still leaves the explicit `renderer=None` path less direct.
- I considered changing `_tight_bbox.adjust_bbox` to pass a renderer to every
  locator, but rejected it as broader than necessary and outside the
  axes-grid-specific failure path described by the issue.
- I did not add or modify tests, and I did not run tests or execute project code
  because the task instructions forbid doing so in this benchmark workspace.
