# Baseline Notes

## Root cause

`Figure.subfigures(..., wspace=..., hspace=...)` stores the requested spacing
on the `GridSpec` used to place the new `SubFigure` objects, but
`SubFigure._redo_transform_rel_fig` computed each subfigure bbox directly from
only the grid's width and height ratios. That ratio-only calculation always
partitioned the parent into touching cells, so changing `wspace` or `hspace`
had no effect unless constrained layout later replaced the bbox.

## Files changed

- `repo/lib/matplotlib/figure.py`: updated
  `SubFigure._redo_transform_rel_fig` to compute subfigure cell extents with
  GridSpec-style spacing arithmetic. The calculation remains relative to the
  full parent figure/subfigure area, so subfigures do not inherit normal subplot
  margins. Explicit `wspace` and `hspace` values on the GridSpec are honored;
  missing values fall back to zero to preserve the existing default behavior of
  adjacent subfigures. The `Figure.subfigures` docstring was also clarified to
  describe that default.

## Assumptions and alternatives considered

- I assumed the spacing requested by `Figure.subfigures` should affect only the
  subfigure grid itself, not the inner axes layout within each subfigure.
- I assumed default subplot spacing from rcParams should not be applied to
  subfigures automatically. The issue discussion notes existing cases where
  `add_subfigure(gs[i])` should continue to ignore the default GridSpec
  `wspace`/`hspace`; therefore the fix treats only explicitly stored GridSpec
  spacing as meaningful for subfigure placement.
- I considered calling `SubplotSpec.get_position` or `GridSpec.get_grid_positions`
  directly. I rejected that because the normal non-raw path would include
  subplot margins and rcParam spacing, while the raw path forces spacing to zero
  and would still ignore the explicit `subfigures(..., wspace=..., hspace=...)`
  arguments.
- I did not modify tests, and I did not run tests or project code, per the task
  constraints.
