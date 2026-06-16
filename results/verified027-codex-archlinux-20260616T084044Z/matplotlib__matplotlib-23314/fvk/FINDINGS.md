# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public intent and source inspection only.

## F-001: Original invisible 3D axes draw bug

Input: `Axes3D.draw(validRenderer)` with `self.get_visible() == False`, as reached by the issue reproduction after `ax1.set_visible(False)`.

Observed in the pre-fix code: `Axes3D.draw` ran `_unstale_viewLim`, drew `self.patch`, applied aspect, computed projection, drew panes, drew 3D axes, and only then delegated to `Axes.draw`, whose visibility guard was too late to prevent those side effects.

Expected: no draw side effects for the invisible axes. This follows from the issue expected outcome and the `Artist.draw` visibility contract.

Resolution: V1 added, and V2 keeps, an early `if not self.get_visible(): return` in `Axes3D.draw`. This discharges `PO-DRAW-INVISIBLE`.

## F-002: V1 renderer-precondition regression

Input: direct `Axes3D.draw(None)` with `self.get_visible() == False`.

Observed in V1: the new visibility guard returned before checking whether the renderer was `None`.

Expected: preserve `Axes.draw` behavior by raising `RuntimeError('No renderer defined')` before visibility is considered. This is a compatibility/frame obligation for an `Axes.draw` override, not issue-specific behavior.

Resolution: V2 added the inherited renderer guard before the visibility guard. This discharges `PO-DRAW-NONE-RENDERER`.

## F-003: Invisible 3D axes tightbbox/layout contribution

Input: `Axes3D.get_tightbbox(...)` when `self.get_visible() == False`.

Observed in the pre-fix code: `Axes3D.get_tightbbox` called `super().get_tightbbox(...)`, which returns `None` for invisible axes, then continued into the 3D-axis bbox union path.

Expected: return `None` and skip 3D-axis bbox union, matching base axes behavior for invisible axes.

Resolution: V1 added, and V2 keeps, `if ret is None: return None`. This discharges `PO-BBOX-INVISIBLE`.

## NF-001: Adjacent per-axis visibility hypothesis rejected for this patch

Hypothesis considered: also change `mpl_toolkits.mplot3d.axis3d.Axis.draw` or `draw_pane` so `ax.xaxis.set_visible(False)` suppresses those individual 3D axis draw paths.

Reason rejected: the public issue and reproduction are axes-level: `ax1.set_visible(False)` and "The left axes should be invisible." The changed public symbols in this patch are `Axes3D.draw` and `Axes3D.get_tightbbox`; their compatibility obligations are fully covered by `PO-DRAW-*` and `PO-BBOX-*`. Per-axis visibility may be a separate consistency issue, but changing it here would extend the behavioral surface beyond the issue-derived obligation.

Status: no source change in V2.
