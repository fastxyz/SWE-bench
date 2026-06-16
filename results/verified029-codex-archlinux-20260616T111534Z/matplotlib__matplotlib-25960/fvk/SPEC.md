# FVK Spec: Subfigure Spacing

Status: constructed from public intent and static source inspection; not
machine-checked.

## Scope

The audited unit is the manual, non-constrained subfigure placement path:

- `FigureBase.subfigures(...)` in `repo/lib/matplotlib/figure.py`
- `SubFigure._redo_transform_rel_fig(bbox=None)` in
  `repo/lib/matplotlib/figure.py`

The observable is each `SubFigure.bbox_relative` extent in parent
figure/subfigure coordinates. The constrained-layout path that passes
`bbox != None` is a frame condition: it must keep replacing the bbox with the
layout-engine result.

## Intent Spec

1. `Figure.subfigures(nrows, ncols, wspace=W, hspace=H)` must make `W` and `H`
   affect the gaps between subfigure columns and rows.
2. `W` is a fraction of the average subfigure cell width; `H` is a fraction of
   the average subfigure cell height.
3. Width and height ratios must continue to determine relative cell sizes.
4. With no explicit subfigure spacing, ordinary subfigures should remain
   adjacent. They should not inherit the normal subplot rcParam spacing.
5. `add_subfigure(gs[i])` should keep historical behavior: a generic GridSpec's
   subplot `wspace`/`hspace` is not automatically subfigure spacing.
6. Constrained layout may still override subfigure positions by passing an
   explicit bbox.

## Public Evidence Ledger

| Id | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | Issue | "`wspace` and `hspace` in `Figure.subfigures` do nothing." | Changing `W` or `H` must change subfigure bbox gaps when a grid has more than one column or row. |
| E2 | `Figure.subfigures` docstring | Spacing is "reserved for space between subfigures" and expressed as "a fraction of the average subfigure width/height." | Use the same average-cell denominator convention as `GridSpec.get_grid_positions`. |
| E3 | Public hint | "position logic could be borrowed from Axes" and links `GridSpec.get_grid_positions`. | Manual subfigure positions should use GridSpec-style cell and separator arithmetic. |
| E4 | Public hint | Existing default examples/tests should not gain unwanted whitespace; "Can we just make the default wspace for subfigures be zero?" | Missing subfigure spacing defaults to zero in the manual path. |
| E5 | Public hint | "subfigures ignores the grid spec wspace ... and if we want a wspace for a set of subfigures that be a kwarg of the subfigure call." | Subfigure spacing must be sourced from `Figure.subfigures` kwargs, not arbitrary GridSpec subplot spacing. |
| E6 | Source | `_constrained_layout.reposition_axes` calls `_redo_transform_rel_fig(bbox=...)`. | The explicit bbox branch must remain a direct assignment. |

## Mathematical Contract

Domain assumptions:

- `nrows > 0`, `ncols > 0`.
- `sum(width_ratios) > 0` and `sum(height_ratios) > 0`.
- `ncols + W * (ncols - 1) > 0` and
  `nrows + H * (nrows - 1) > 0`.
- `rowspan` and `colspan` are non-empty contiguous ranges within the grid.

These match ordinary GridSpec/subfigure use. Exotic negative spacing or
non-positive ratio sums are outside this proof and recorded as residual risk in
`FINDINGS.md`.

For a grid created by `Figure.subfigures`, let

```text
W = 0 if _subfigure_wspace is None else _subfigure_wspace
H = 0 if _subfigure_hspace is None else _subfigure_hspace
```

For a grid not created by `Figure.subfigures`, the `_subfigure_*` attributes are
absent and therefore `W = H = 0`.

Column geometry:

```text
base_w = 1 / (ncols + W * (ncols - 1))
sep_w = W * base_w
cell_w[j] = width_ratios[j] * base_w * ncols / sum(width_ratios)
left[j] = sum_{k < j} cell_w[k] + j * sep_w
right[j] = left[j] + cell_w[j]
```

Row geometry, with row 0 at the top:

```text
base_h = 1 / (nrows + H * (nrows - 1))
sep_h = H * base_h
cell_h[i] = height_ratios[i] * base_h * nrows / sum(height_ratios)
top[i] = 1 - sum_{k < i} cell_h[k] - i * sep_h
bottom[i] = top[i] - cell_h[i]
```

For a subfigure spanning columns `c0..c1-1` and rows `r0..r1-1`, the required
bbox is:

```text
x0 = min(left[c] for c in c0..c1-1)
x1 = max(right[c] for c in c0..c1-1)
y0 = min(bottom[r] for r in r0..r1-1)
y1 = max(top[r] for r in r0..r1-1)
```

Because spans are contiguous and the arrays are monotone in ordinary domains,
this is equivalent to `left[c0]`, `right[c1-1]`, `bottom[r1-1]`, `top[r0]`.

## Frame Conditions

- The public signatures of `subfigures`, `add_subfigure`, and
  `_redo_transform_rel_fig` do not change.
- `GridSpec.wspace` and `GridSpec.hspace` are still passed by `subfigures` for
  constrained-layout consumers, but manual subfigure layout reads only the
  private `_subfigure_wspace` / `_subfigure_hspace` metadata.
- `bbox != None` remains a direct overwrite of `bbox_relative.p0` and
  `bbox_relative.p1`.

## K Artifacts

The constructed K core is:

- `fvk/mini-subfigure-layout.k`
- `fvk/subfigure-layout-spec.k`

Commands to machine-check later, not executed here:

```sh
kompile fvk/mini-subfigure-layout.k --backend haskell
kast --backend haskell fvk/subfigure-layout-spec.k
kprove fvk/subfigure-layout-spec.k
```
