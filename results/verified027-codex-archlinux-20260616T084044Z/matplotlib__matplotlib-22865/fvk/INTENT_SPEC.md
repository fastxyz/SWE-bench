# Intent Spec

Status: constructed for FVK audit; not machine-checked.

## Required behavior

1. `drawedges=True` means the colorbar draws lines at color boundaries.
2. For an extended colorbar, the boundary between each extension color and the
   main colorbar body is a color boundary.
3. With `extend='both'`, both extremity join boundaries must be drawn.
4. By the public `extend` contract, `extend='min'` and `extend='max'` identify
   the data minimum and data maximum sides respectively.  Therefore a minimum
   extension requires the first main-body boundary segment, and a maximum
   extension requires the last main-body boundary segment.
5. For non-extended sides, the existing colorbar outline remains responsible
   for the exterior edge.  The divider collection should not add extra end
   segments there.
6. `drawedges=False` must continue to produce no divider segments.
7. The fix must not change the public `Colorbar` / `ColorbarBase` API,
   accepted `extend` values, orientation behavior, colormap/norm handling, or
   colorbar body generation.

## Domain

The FVK model covers the divider segment selection performed by
`Colorbar._add_solids` after `_mesh()` has produced one boundary row per
main-body color boundary.  Let `N` be the number of boundary rows, with
`N >= 2` for at least one main color cell.  The public `extend` value is one of
`'neither'`, `'min'`, `'max'`, or `'both'`; `drawedges` is boolean.

Coordinates, colors, hatching, and rendering backend details are frame
conditions for this audit.  The property under verification is the half-open
index range of boundary rows passed to `self.dividers.set_segments`.
