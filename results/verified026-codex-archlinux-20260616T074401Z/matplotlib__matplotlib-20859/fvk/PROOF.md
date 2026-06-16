# Constructed Proof

Status: constructed, not machine-checked.  No K commands were executed.

## Artifacts

Formal core:

- `fvk/mini-python-subfigure-legend.k`
- `fvk/subfigure-legend-spec.k`

Adequacy and compatibility:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## Machine-check Commands Not Run

The following are the commands a later environment with K installed should run:

```sh
kompile fvk/mini-python-subfigure-legend.k --backend haskell
kast --backend haskell fvk/subfigure-legend-spec.k
kprove fvk/subfigure-legend-spec.k
```

Expected result after machine-checking: all claims discharge to `#Top`.

## Adequacy Gate

The intent-only spec requires that `SubFigure.legend()` create a legend rather
than raising `TypeError`, while preserving axes legends, figure legends, and
invalid-parent rejection.  The formal-English paraphrase states exactly those
properties.  `SPEC_AUDIT.md` marks all claims as pass, and
`PUBLIC_COMPATIBILITY_AUDIT.md` has no unhandled public callsite or override.

## Proof Sketch

### C-001: Subfigure parent acceptance and ownership

Initial symbolic state:

- `<k> figureBaseLegend(subfigure) </k>`
- `<legends> .List </legends>`

Step 1, expand the `FigureBase.legend()` abstraction:

`figureBaseLegend(subfigure)` rewrites to
`legendInit(subfigure) ~> appendLegend(subfigure)`.

Step 2, classify the parent:

`isAxes(subfigure)` is false.  `isFigureBase(subfigure)` is true because
`SubFigure` inherits from `FigureBase`.  Therefore `legendInit(subfigure)`
rewrites to `created(false, subfigure)`.

Step 3, append ownership:

`created(false, subfigure) ~> appendLegend(subfigure)` rewrites to
`created(false, subfigure)`, while the `<legends>` cell changes from `.List` to
`ListItem(legend(subfigure))`.

Conclusion: `SubFigure.legend()` creates a non-axes legend owned by the
subfigure.  This discharges PO-001, PO-002, and PO-005.

### C-002: Axes and Figure behavior

For `axes`, `isAxes(axes)` is true, so `legendInit(axes)` rewrites to
`created(true, axes)`.  The axes branch is checked first, matching the source
order and preserving `Axes.legend()`.

For `figure`, `isAxes(figure)` is false and `isFigureBase(figure)` is true, so
`legendInit(figure)` rewrites to `created(false, figure)`.  This is the same
non-axes classification that concrete `Figure` had before V1.

Conclusion: PO-003 and the figure part of PO-004 are discharged.

### C-003: Invalid parents

For `other`, `isAxes(other)` is false and `isFigureBase(other)` is false.
Therefore `legendInit(other)` rewrites to `typeError` and no legend is added.

Conclusion: the invalid-parent part of PO-004 is discharged.

### C-004: Subfigure bbox includes owned legend

Initial symbolic state:

- `<k> subfigureTightbbox </k>`
- `<legends> ListItem(legend(subfigure)) .List </legends>`

`subfigureTightbbox` rewrites to `includesLegend` when the subfigure's legend
list contains `legend(subfigure)`.

Source composition:

1. `FigureBase.get_children()` includes `*self.legends`.
2. `FigureBase.get_default_bbox_extra_artists()` selects visible, in-layout
   children.
3. `FigureBase.get_tightbbox()` calls each selected artist's
   `get_tightbbox(renderer)`.
4. The top-level figure includes the `SubFigure` object in `self.subfigs` and
   calls the subfigure's tight bbox as an extra artist.

Conclusion: the hinted tight-bbox concern is covered by subfigure ownership and
existing bbox traversal.  PO-006 and PO-007 are discharged without changing
`FigureBase.get_default_bbox_extra_artists()`.

## Residual Risk

This is a partial-correctness proof over a purpose-built mini semantics.  It
does not prove renderer geometry, termination, image output equality, or the
entire Matplotlib legend system.  The key residual risk is that the proof has
not been machine-checked because this task forbids running K tooling.

## Test Guidance

No test files were modified.  After machine-checking, maintainers could add a
focused regression test that calls `subfig.legend()` and asserts the returned
legend is present in `subfig.legends`.  A tight-bbox integration/image test is
still useful because renderer geometry is outside this mini semantics.
