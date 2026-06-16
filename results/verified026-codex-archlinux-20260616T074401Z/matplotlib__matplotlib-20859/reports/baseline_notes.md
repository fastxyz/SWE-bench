# Baseline Notes

## Root cause

`SubFigure.legend()` uses the shared `FigureBase.legend()` implementation, which
constructs a `Legend` with the `SubFigure` itself as the parent.  The
`Legend` constructor only accepted parents that were `Axes` or the concrete
`Figure` class, so a valid `SubFigure` parent was rejected before the legend
could be created.

`SubFigure` already inherits from `FigureBase`, and `FigureBase` is the common
base for both `Figure` and `SubFigure`.  Treating `FigureBase` parents as
non-axes legend parents preserves the existing figure behavior while allowing
subfigure legends to use the same path.

## Files changed

- `repo/lib/matplotlib/legend.py`: updated the lazy figure import and parent
  type check in `Legend.__init__` from the concrete `Figure` class to
  `FigureBase`, and adjusted the constructor documentation/error message to
  match the accepted parent type.

## Assumptions and alternatives considered

- I assumed the intended behavior is for a `SubFigure` legend to behave like a
  figure legend scoped to the subfigure, because `SubFigure.legend()` already
  exists through `FigureBase.legend()` and passes `self` as the parent.
- I considered checking explicitly for both `Figure` and `SubFigure`, but
  rejected that because `FigureBase` is the local shared abstraction for these
  methods and matches the public hint in the issue.
- I considered changing `FigureBase.get_default_bbox_extra_artists()` based on
  the follow-up discussion in the issue, but rejected that for this fix because
  the root failure is the constructor rejecting `SubFigure`; the existing
  `FigureBase` child/drawing model already includes legends owned by a
  subfigure, and the issue discussion treats the broader bbox behavior as a
  separate follow-up.
