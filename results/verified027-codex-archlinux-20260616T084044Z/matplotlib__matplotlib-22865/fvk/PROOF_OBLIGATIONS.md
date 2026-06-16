# Proof Obligations

Status: constructed for FVK audit; not machine-checked.

## PO1: Domain and abstraction

For `N >= 2`, `Rows = np.dstack([X, Y])` has one row for each main-body
boundary segment.  The FVK model abstracts `Rows[i]` to index `i`; this keeps
the endpoint inclusion property observable.

## PO2: Disabled drawedges

If `drawedges` is false, `self.dividers.set_segments([])` must be called.

## PO3: Non-extended sides

If the minimum side is not extended, the first row is excluded because the
outline supplies that exterior edge.  If the maximum side is not extended, the
last row is excluded for the same reason.

## PO4: Minimum extension boundary

If `extend` is `'min'` or `'both'`, the first row must be included because it is
the join between the minimum extension patch and the main colorbar body.

## PO5: Maximum extension boundary

If `extend` is `'max'` or `'both'`, the last row must be included because it is
the join between the maximum extension patch and the main colorbar body.

## PO6: Orientation frame condition

`_mesh()` returns `(X, Y)` for vertical colorbars and `(Y, X)` for horizontal
colorbars.  This swaps coordinate components but preserves row identity and
row order, so the same first/interior/last row selection works for both
orientations.

## PO7: Python slice correspondence

For a sequence of length `N`:

- `Rows[1:-1]` selects `range(1, N - 1)`;
- `Rows[0:-1]` selects `range(0, N - 1)`;
- `Rows[1:None]` selects `range(1, N)`;
- `Rows[0:None]` selects `range(0, N)`.

V1's `start` and `stop` values must map to those four cases.

## PO8: Compatibility frame

The patch must leave constructor APIs, valid `extend` values, mappable/norm
handling, body mesh generation, extension patch generation, and `LineCollection`
styling unchanged.

## PO9: Machine-check commands are recorded but not run

The K proof artifacts are constructed only.  Per task constraints, `kompile`,
`kast`, and `kprove` are not executed in this environment.
