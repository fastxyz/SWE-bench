# FVK Specification: SubFigure Legend Parent

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `matplotlib__matplotlib-20859`.  The
observable under audit is the public `SubFigure.legend()` path:

1. `FigureBase.legend()` parses handles and labels for the axes owned by the
   figure-like object.
2. It constructs `mlegend.Legend(self, handles, labels, ...)`.
3. It appends the created legend to `self.legends`, installs the legend removal
   method, marks the parent stale, and returns the legend.

The critical implementation point is `Legend.__init__`, which classifies the
legend parent as either axes-owned or figure-like.

## Intent Specification

I-001: Calling `subfig.legend()` on a `SubFigure` with labeled artists is
in-domain and must create a legend rather than raising `TypeError`.

I-002: A subfigure legend is figure-like rather than axes-owned: it should use
the non-axes legend path, so automatic `loc='best'` remains unavailable and the
default non-axes location handling applies.

I-003: Existing `Axes.legend()` and `Figure.legend()` behavior must be
preserved.

I-004: Invalid direct `Legend` parents that are neither `Axes` nor figure-like
containers must still be rejected.

I-005: A legend owned by a `SubFigure` must be an owned child of that
subfigure, so drawing and tight-bbox traversal can reach it through the
subfigure object.

## Public Evidence Ledger

E-001, prompt: "Adding a legend to a `SubFigure` doesn't work" and the
reproduction ending in `subfig.legend()`.  Obligation: `SubFigure.legend()` is
an intended public call.

E-002, prompt: "I'd expect this to work and produce a legend" and "it would be
useful to allow a legend per subfigure."  Obligation: successful legend
creation for a subfigure parent.

E-003, prompt hint: "Changing L437 here to check against `FigureBase` fixes
it."  Obligation: accept the common figure base class, not only the concrete
`Figure` class.

E-004, maintainer hint: "Yep that was just an oversight, not a design decision
;-)"  Obligation: the rejection of `SubFigure` is accidental, not intended API
behavior.

E-005, source docstring: `FigureBase` is the "Base class for `.figure.Figure`
and `.figure.SubFigure` containing the methods that add artists to the figure
or subfigure, create Axes, etc."  Obligation: `FigureBase` is the local shared
abstraction for this behavior.

E-006, source code: `FigureBase.legend()` passes `self` to
`mlegend.Legend(...)`, then appends the result to `self.legends`.  Obligation:
the constructor must accept every valid `FigureBase.legend()` receiver.

E-007, public hint: the follow-up says `fig.get_default_bbox_extra_artists()`
"doesn't include the legend" and suggests changing that method; a later hint
says `get_default_bbox_extra_artists` should probably "only return SubFigure,
and its bbox should include the legend."  Obligation: audit the bbox path as a
proof obligation, not as a scope-only dismissal.

## Formal Model

The supporting K model is intentionally small:

- `fvk/mini-python-subfigure-legend.k` models only the parent-class
  classification, `FigureBase.legend()` ownership append, invalid-parent
  rejection, and subfigure tight-bbox inclusion of owned legends.
- `fvk/subfigure-legend-spec.k` states the proof claims for this issue.

The model abstracts away renderer geometry, handle/label parsing internals, and
pixel coordinates because the public issue is not about layout arithmetic.  It
preserves the property under verification: whether a subfigure parent is
accepted, how the legend is classified, whether the legend is owned by the
subfigure, and whether the subfigure bbox path can include the legend.

## Claims

C-001, subfigure parent acceptance:
`figureBaseLegend(subfigure)` reaches `created(false, subfigure)` and appends
`legend(subfigure)` to the parent's legend list.

C-002, existing axes and figure behavior:
`legendInit(axes)` reaches `created(true, axes)`, and
`legendInit(figure)` reaches `created(false, figure)`.

C-003, invalid parent rejection:
`legendInit(other)` reaches `typeError` and does not create a legend.

C-004, subfigure bbox traversal:
Given a subfigure-owned legend in the subfigure's `legends` list,
`subfigureTightbbox` reaches `includesLegend`.

C-005, adequacy:
The English paraphrase of C-001 through C-004 matches I-001 through I-005 and
does not rely on legacy behavior as the expected result.

## Compatibility

Only `Legend.__init__` parent classification changed in V1.  Public callsites
found in source are:

- `Axes.legend()`, which passes an `Axes` and remains on the axes branch.
- `FigureBase.legend()`, which passes `self`; this covers both `Figure` and
  `SubFigure`.

`FigureBase` has only the concrete `Figure` and `SubFigure` subclasses in this
source tree, so using `FigureBase` is equivalent to accepting the intended
figure-like parent family.

## Decision

V1 satisfies the intent and proof obligations.  No V2 source edit is required.
The hinted bbox issue is discharged by the current ownership and bbox traversal
model: `Figure.get_tightbbox()` includes the `SubFigure` artist, and
`SubFigure.get_tightbbox()` uses `SubFigure.get_default_bbox_extra_artists()`,
whose children include `self.legends`.
