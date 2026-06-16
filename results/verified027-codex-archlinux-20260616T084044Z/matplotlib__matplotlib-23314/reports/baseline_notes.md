# Baseline Notes

## Root cause

`Axes3D.draw` overrides the base `Axes.draw` implementation and draws 3D-specific content before delegating to `super().draw(renderer)`. The base implementation already returns early when `self.get_visible()` is false, but in the 3D override that check happened too late: the background patch, 3D panes, and 3D axis artists had already been drawn. As a result, `ax.set_visible(False)` on a 3D axes did not hide the axes frame/panes in the reported subplot example.

`Axes3D.get_tightbbox` had the same inheritance mismatch for invisible axes. It called the base method, which returns `None` for invisible axes, but then continued into its 3D-axis bbox union path. Preserving the base `None` result keeps invisible 3D axes out of layout calculations consistently with 2D axes.

## Changed files

`repo/lib/mpl_toolkits/mplot3d/axes3d.py`

- Added an early `if not self.get_visible(): return` guard at the start of `Axes3D.draw`, before any 3D-specific drawing or projection work.
- Added an early `return None` in `Axes3D.get_tightbbox` when the base `Axes.get_tightbbox` reports that the axes is invisible.

## Assumptions and alternatives considered

The issue reproduction calls `ax1.set_visible(False)`, so I treated the bug as axes-level visibility, not per-axis visibility such as `ax.xaxis.set_visible(False)`.

I considered changing the loops that draw each 3D axis pane and axis line to check each individual axis object's visibility. That may be a separate consistency improvement, but it is broader than the reported axes-level failure and could change behavior outside the minimal bug fix.

I also considered relying only on `super().draw(renderer)` to skip invisible axes. That cannot fix the bug because the 3D override draws the patch, panes, and axis artists before calling the base method.
