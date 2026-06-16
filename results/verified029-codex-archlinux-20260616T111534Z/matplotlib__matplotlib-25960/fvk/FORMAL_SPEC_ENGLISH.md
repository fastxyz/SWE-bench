# Formal Spec In English

Status: paraphrase of the constructed K claims; not machine-checked.

## CLAIM FIGURE-SUBFIGURES-STORES-SPACING

When `subfigures` is called with `wspace=W_arg` and `hspace=H_arg`, the GridSpec
used for the returned SubFigures carries `_subfigure_wspace = W_arg` and
`_subfigure_hspace = H_arg`.

## CLAIM SUBFIGURE-LAYOUT

For in-domain grid dimensions, ratios, spacing values, and row/column spans,
`_redo_transform_rel_fig(bbox=None)` computes column widths, row heights, and
separators using the average-cell formula from `SPEC.md`; then it sets
`bbox_relative` to the min/max extents of the spanned rows and columns.

## CLAIM DEFAULT-ADD-SUBFIGURE-ZERO-SPACING

If the GridSpec has no `_subfigure_wspace` or `_subfigure_hspace`, manual
subfigure layout uses zero spacing, regardless of generic GridSpec subplot
spacing attributes. If only one subfigure-specific spacing value is missing or
`None`, only that axis defaults to zero.

## CLAIM BBOX-OVERRIDE

If `_redo_transform_rel_fig` receives an explicit bbox, it copies that bbox into
`bbox_relative` and does not compute manual GridSpec positions.
