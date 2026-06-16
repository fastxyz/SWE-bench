# Formal Spec, In English

Status: constructed for FVK audit; not machine-checked.

The K claims in `fvk/colorbar-segments-spec.k` say:

- C1: For any valid extension state and any `N >= 2`, if `drawedges` is false,
  selected divider segments are empty.
- C2: For `drawedges=True` and `extend='neither'`, selected divider segments
  are the interior boundaries only: `range(1, N - 1)`.
- C3: For `drawedges=True` and `extend='min'`, selected divider segments
  include the minimum extension/body join and all interior boundaries, but not
  the maximum exterior edge: `range(0, N - 1)`.
- C4: For `drawedges=True` and `extend='max'`, selected divider segments
  include all interior boundaries and the maximum extension/body join, but not
  the minimum exterior edge: `range(1, N)`.
- C5: For `drawedges=True` and `extend='both'`, selected divider segments
  include every main-body boundary row, including both extension/body joins:
  `range(0, N)`.

The proof obligations in `fvk/PROOF_OBLIGATIONS.md` add the frame conditions:
orientation swaps coordinate components but keeps row identity; non-extended
outer edges remain supplied by the outline; and no public API or caller contract
changes.
