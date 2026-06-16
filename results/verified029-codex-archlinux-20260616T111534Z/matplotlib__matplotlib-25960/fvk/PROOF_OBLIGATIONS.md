# FVK Proof Obligations

Status: constructed from public intent and static source inspection; not
machine-checked.

## PO1 - Subfigure Kwargs Are Stored As Subfigure Spacing

For every call to
`FigureBase.subfigures(..., wspace=W_arg, hspace=H_arg, ...)`, the GridSpec used
to create the returned SubFigures has:

```text
_subfigure_wspace = W_arg
_subfigure_hspace = H_arg
```

Source obligation: E1, E2, E5.

Discharged by V2 source: assignment immediately after GridSpec construction in
`FigureBase.subfigures`.

## PO2 - `None` Subfigure Spacing Means Zero In Manual Layout

If `_subfigure_wspace is None`, manual layout uses `W = 0.0`. If
`_subfigure_hspace is None`, manual layout uses `H = 0.0`.

Source obligation: E4.

Discharged by V2 source: the fallback branches in `_redo_transform_rel_fig`.

## PO3 - Cell Widths And Heights Use Average-Cell Spacing

For in-domain inputs, the manual layout computes:

```text
base_w = 1 / (ncols + W * (ncols - 1))
sep_w = W * base_w
cell_w[j] = width_ratios[j] * base_w * ncols / sum(width_ratios)

base_h = 1 / (nrows + H * (nrows - 1))
sep_h = H * base_h
cell_h[i] = height_ratios[i] * base_h * nrows / sum(height_ratios)
```

Source obligation: E2, E3.

Discharged by V2 source: the `cell_w`, `sep_w`, `norm`, `cell_widths`,
`cell_h`, `sep_h`, `norm`, and `cell_heights` calculations in
`_redo_transform_rel_fig`.

## PO4 - SubplotSpec Spans Map To The Correct Bbox Extents

For each subfigure span, the bbox is:

```text
x0 = min(lefts[colspan])
x1 = max(rights[colspan])
y0 = min(bottoms[rowspan])
y1 = max(tops[rowspan])
```

This includes gaps internal to a multi-cell span and excludes gaps outside the
span.

Source obligation: E2, E3.

Discharged by V2 source: the final `min`/`max` extraction and
`Bbox.from_extents` / `p0` / `p1` assignments.

## PO5 - Generic `add_subfigure(GridSpec[...])` Does Not Inherit GridSpec Spacing

If a GridSpec was not created by `FigureBase.subfigures`, it has no
`_subfigure_wspace` / `_subfigure_hspace` metadata. Manual layout therefore
uses `W = H = 0.0`, regardless of generic `gs.wspace` or `gs.hspace`.

Source obligation: E4, E5.

Discharged by V2 source: `_redo_transform_rel_fig` reads only `_subfigure_*`
metadata and no longer reads `gs.wspace`, `gs.hspace`, `gs._wspace`, or
`gs._hspace`.

## PO6 - Explicit Bbox Override Is A Direct Assignment

If `_redo_transform_rel_fig(bbox=B)` is called, then `bbox_relative.p0 = B.p0`
and `bbox_relative.p1 = B.p1`, and no GridSpec arithmetic runs.

Source obligation: E6.

Discharged by V2 source: unchanged early return in `_redo_transform_rel_fig`.

## PO7 - Constrained Layout Still Receives GridSpec Spacing

`FigureBase.subfigures` still passes `wspace` and `hspace` into `GridSpec(...)`,
so constrained-layout code that reads `gs.wspace` and `gs.hspace` continues to
see the same values as before V2.

Source obligation: E6 and compatibility with existing constrained-layout path.

Discharged by V2 source: the GridSpec constructor call is unchanged from V1 for
`wspace` and `hspace`.

## PO8 - Public API Shape Is Unchanged

No public function signature, return shape, or callsite protocol is changed.

Source obligation: public compatibility.

Discharged by V2 source: changes are internal assignments and internal bbox
arithmetic only.

## PO9 - Proof Domain Preconditions Are Named

The constructed proof assumes positive grid dimensions, positive ratio sums,
and nonzero spacing denominators. Inputs outside that domain are not used to
justify correctness.

Source obligation: FVK adequacy and honest residual-risk reporting.

Discharged by artifacts: `SPEC.md` domain assumptions and `FINDINGS.md` F4.
