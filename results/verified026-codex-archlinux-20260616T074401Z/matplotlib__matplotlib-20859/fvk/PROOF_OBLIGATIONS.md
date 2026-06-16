# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: `SubFigure.legend()` reaches `Legend.__init__` with a valid parent

Evidence: E-001, E-002, E-006.

Code path: `FigureBase.legend()` is inherited by `SubFigure`; it calls
`mlegend.Legend(self, handles, labels, ...)`.

Obligation: when `self` is a `SubFigure`, `Legend.__init__` must not raise the
invalid-parent `TypeError`.

Formal claim: C-001 in `fvk/subfigure-legend-spec.k`.

Status: discharged by V1, because `SubFigure` is a `FigureBase`.

## PO-002: Subfigure legends use the non-axes legend branch

Evidence: E-002, E-003, E-005.

Code path: the non-axes branch sets `self.isaxes = False` and calls
`self.set_figure(parent)`.

Obligation: `SubFigure` must be classified like `Figure`, not like `Axes`.

Formal claim: C-001.

Status: discharged by V1.  `FigureBase` includes `SubFigure`, so the
non-axes branch is selected.

## PO-003: Axes legend behavior is preserved

Evidence: existing source callsite `Axes.legend()` passes `self`, an `Axes`.

Code path: `Axes.legend()` constructs `mlegend.Legend(self, ...)`.

Obligation: axes parents still select the axes branch, set `isaxes = True`, and
set the legend figure from `parent.figure`.

Formal claim: C-002.

Status: discharged.  The axes branch is unchanged and is checked before the
`FigureBase` branch.

## PO-004: Ordinary `Figure.legend()` and invalid-parent behavior are preserved

Evidence: E-003, E-004, source callsite `FigureBase.legend()`.

Code path: `Figure.legend()` passes a concrete `Figure`, which is a
`FigureBase`; arbitrary objects are not `Axes` or `FigureBase`.

Obligation: a concrete `Figure` still creates a non-axes legend, and an
unrelated parent still raises `TypeError`.

Formal claims: C-002 and C-003.

Status: discharged.  `Figure` remains accepted through `FigureBase`; unrelated
objects remain rejected.

## PO-005: Created subfigure legend is owned by the subfigure

Evidence: E-006.

Code path: after construction, `FigureBase.legend()` appends the legend to
`self.legends`, sets `l._remove_method = self.legends.remove`, marks
`self.stale = True`, and returns `l`.

Obligation: for a `SubFigure` receiver, the created legend must be recorded in
that subfigure's `legends` list.

Formal claim: C-001.

Status: discharged by existing `FigureBase.legend()` code once
`Legend.__init__` no longer raises.

## PO-006: Subfigure tight-bbox traversal can include the owned legend

Evidence: E-007 and source `FigureBase.get_children()` /
`FigureBase.get_default_bbox_extra_artists()` / `FigureBase.get_tightbbox()`.

Code path: `FigureBase.get_children()` includes `*self.legends`.
`get_default_bbox_extra_artists()` filters visible/in-layout children.
`get_tightbbox()` calls `get_tightbbox(renderer)` on every default extra
artist when `bbox_extra_artists is None`.

Obligation: a visible, in-layout subfigure legend owned by `subfig.legends` is
reachable from `subfig.get_tightbbox()`.

Formal claim: C-004.

Status: discharged by existing source.  No `FigureBase.get_default_bbox_extra_artists`
edit is required for this issue.

## PO-007: Top-level tight-bbox traversal reaches the subfigure

Evidence: E-007 and source `FigureBase.get_children()` includes
`*self.subfigs`.

Code path: the top-level figure's default extra artists include the visible,
in-layout `SubFigure`; `Figure.get_tightbbox()` asks each default extra artist
for its tight bbox.

Obligation: the top-level figure can reach the subfigure's tight bbox, which
by PO-006 includes the subfigure legend.

Formal claim: C-004 plus the source-level composition described in
`PROOF.md`.

Status: discharged by source audit.  The direct list printed by
`fig.get_default_bbox_extra_artists()` need not contain the legend object if it
contains the `SubFigure` object whose bbox includes that legend.
