# Intent Spec

This file is intent-only: it records required behavior from public evidence
before accepting candidate implementation behavior as expected.

I-001: `SubFigure.legend()` is an intended public call and must create a legend
instead of raising `TypeError`.

I-002: A subfigure legend is figure-like, not axes-owned.  It must use the
non-axes legend behavior used for figure legends.

I-003: `Axes.legend()` and `Figure.legend()` must keep their existing parent
classification behavior.

I-004: The issue does not make arbitrary direct `Legend` parents valid.
Invalid parents should still raise `TypeError`.

I-005: A legend created by `SubFigure.legend()` must be owned by the subfigure
so it participates in drawing and tight-bbox traversal through the subfigure.

I-006: The hinted bbox concern must be audited.  It is acceptable for the
top-level figure's default extra-artist list to include the `SubFigure` rather
than the legend directly if the subfigure's tight bbox includes the legend.
