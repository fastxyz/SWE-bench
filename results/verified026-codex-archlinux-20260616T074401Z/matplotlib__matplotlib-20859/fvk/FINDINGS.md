# FVK Findings

Status: constructed, not machine-checked.

## F-001: Pre-V1 rejected an in-domain `SubFigure` parent

Input: the issue reproduction calls `subfig.legend()` after plotting a labeled
line on a subfigure-owned axes.

Observed before V1: `Legend.__init__` accepted `Axes` and concrete `Figure`
parents only, so the `SubFigure` parent reached the invalid-parent branch and
raised `TypeError`.

Expected: public intent says the call should work and produce a legend, and the
public hint identifies `FigureBase` as the intended type check.

Status: resolved by V1.  `Legend.__init__` now accepts `FigureBase`, which
covers both `Figure` and `SubFigure`.

Related proof obligations: PO-001, PO-002, PO-005.

## F-002: Hinted tight-bbox issue required audit, not scope dismissal

Input: the public hint creates a figure, adds a subfigure, calls
`subfig.legend()`, and then considers `fig.get_default_bbox_extra_artists()` /
`bbox_inches="tight"`.

Observed in source after V1: the top-level figure's default extra artists do
not list the subfigure legend directly, but they do include the `SubFigure`
artist.  The subfigure's own `get_default_bbox_extra_artists()` includes its
`legends`, and `get_tightbbox()` calls `get_tightbbox()` on those artists.

Expected: the proof-relevant property is that saving or tight-bbox traversal
can include the subfigure legend through the subfigure's bbox.  The later public
hint explicitly points in that direction: the top-level method should return
the subfigure, and the subfigure bbox should include the legend.

Status: audited and discharged without a source change.  V1 creates an owned
subfigure legend, and existing `FigureBase` bbox traversal reaches it through
the subfigure object.

Related proof obligations: PO-006, PO-007.

## F-003: Existing axes and figure legend behavior must be preserved

Input: existing `Axes.legend()` and `Figure.legend()` public paths.

Observed after V1: `Axes.legend()` still passes an `Axes` parent and takes the
axes branch.  `Figure.legend()` still passes a concrete `Figure`, which is a
`FigureBase`, and takes the non-axes branch.

Expected: the issue only expands valid figure-like parents; it does not justify
changing axes legends or ordinary figure legends.

Status: no regression found by source audit.

Related proof obligations: PO-003, PO-004.

## F-004: Invalid direct `Legend` parents remain out of domain

Input: a direct `Legend` construction with a parent that is neither `Axes` nor
`FigureBase`.

Observed after V1: such a parent still reaches the TypeError branch.

Expected: the issue does not require accepting arbitrary parents.

Status: preserved.

Related proof obligations: PO-004.

## F-005: Proof not machine-checked in this environment

Input: the K artifacts in this directory.

Observed: commands are written in `PROOF.md`, but the task forbids running
`kompile`, `kast`, or `kprove`.

Expected: the FVK MVP permits constructed proofs but requires explicit honesty
labeling.

Status: residual verification risk.  The proof is constructed, not
machine-checked.

Related proof obligations: all.
