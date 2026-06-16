# Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V1 stands unchanged.  The FVK audit did not surface a source defect that
requires a V2 edit.

## Why No Source Change Is Needed

- F-001 / PO-001 / PO-002 show that the actual reported failure was the
  constructor rejecting `SubFigure`.  V1 fixes this by checking `FigureBase`.
- F-003 / PO-003 / PO-004 show that existing `Axes` and concrete `Figure`
  behavior is preserved.
- F-002 / PO-006 / PO-007 audit the hinted bbox concern as a real hypothesis.
  The proof obligation is discharged by the current object ownership and bbox
  traversal: the legend is owned by the subfigure, the subfigure's children
  include its legends, and the top-level figure reaches the subfigure bbox.

## Suggested Follow-up Tests

Do not modify tests in this task.  Future maintainers should consider adding:

1. A regression test that creates a subfigure, plots a labeled artist, calls
   `subfig.legend()`, and asserts the returned legend is in `subfig.legends`.
2. A static behavior assertion that the returned subfigure legend has
   `isaxes == False`.
3. A tight-bbox integration test for `bbox_inches="tight"` if the project wants
   renderer-level coverage beyond the FVK mini semantics.

## Machine-check Follow-up

Run these commands in an environment with K installed:

```sh
kompile fvk/mini-python-subfigure-legend.k --backend haskell
kast --backend haskell fvk/subfigure-legend-spec.k
kprove fvk/subfigure-legend-spec.k
```

Until `kprove` returns `#Top`, the proof remains constructed, not
machine-checked, and no test-removal recommendation should be acted on.
