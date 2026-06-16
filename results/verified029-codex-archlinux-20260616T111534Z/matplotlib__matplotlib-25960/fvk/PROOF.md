# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
commands were run.

## Claims Proved By Construction

The proof targets the mathematical contract in `SPEC.md` and the claims in
`subfigure-layout-spec.k`:

- `FIGURE-SUBFIGURES-STORES-SPACING`: `FigureBase.subfigures` stores its
  `wspace` and `hspace` kwargs as subfigure-specific spacing metadata.
- `SUBFIGURE-LAYOUT`: `_redo_transform_rel_fig(bbox=None)` maps ratios,
  subfigure-specific spacing, and row/column spans to the required bbox extents.
- `DEFAULT-ADD-SUBFIGURE-ZERO-SPACING`: a GridSpec without subfigure-specific
  metadata uses zero manual subfigure spacing even if generic subplot spacing
  exists.
- `BBOX-OVERRIDE`: `_redo_transform_rel_fig(bbox=B)` directly installs `B`.

## Proof Sketch

### PO1

The V2 `subfigures` implementation constructs one GridSpec and immediately
assigns:

```text
gs._subfigure_wspace = wspace
gs._subfigure_hspace = hspace
```

Every SubFigure returned by the method is then created from a SubplotSpec owned
by that GridSpec, so each call to `_redo_transform_rel_fig` reaches the same
stored subfigure-specific values through
`self._subplotspec.get_gridspec()`.

### PO2 and PO5

The V2 `_redo_transform_rel_fig` reads:

```text
wspace = getattr(gs, "_subfigure_wspace", None)
hspace = getattr(gs, "_subfigure_hspace", None)
```

and then replaces `None` with `0.0`. Therefore:

- a `Figure.subfigures(..., wspace=None, hspace=None)` grid uses zero manual
  spacing on both axes;
- a mixed call such as `wspace=0.2, hspace=None` uses explicit spacing on one
  axis and zero on the missing axis;
- a generic GridSpec passed through `add_subfigure(gs[i])` has no
  `_subfigure_*` metadata and also uses zero manual spacing;
- generic `gs.wspace`, `gs.hspace`, `gs._wspace`, and `gs._hspace` are
  irrelevant to manual subfigure layout.

This closes the V1 compatibility finding F2.

### PO3

For columns, the code sets:

```text
cell_w = 1 / (ncols + W * (ncols - 1))
sep_w = W * cell_w
norm = cell_w * ncols / sum(width_ratios)
cell_widths[j] = width_ratios[j] * norm
```

Thus the total occupied width is:

```text
sum(cell_widths) + (ncols - 1) * sep_w
= sum(width_ratios) * cell_w * ncols / sum(width_ratios)
  + (ncols - 1) * W * cell_w
= cell_w * (ncols + W * (ncols - 1))
= 1
```

Each inter-column gap is exactly `sep_w = W * cell_w`, so `W` is a fraction of
the average cell width. The row proof is identical with `H`, `nrows`, and
height ratios.

### PO4

The code builds cumulative `[separator, cell]` pairs:

```text
cell_ws = cumsum(column_stack([sep_widths, cell_widths]).flat)
lefts  = cell_ws.reshape((-1, 2))[:, 0]
rights = cell_ws.reshape((-1, 2))[:, 1]
```

For column `j`, `lefts[j]` is the total of all prior cells and all prior
separators, and `rights[j] = lefts[j] + cell_widths[j]`. Therefore adjacent
columns satisfy:

```text
lefts[j + 1] - rights[j] = sep_w
```

The row arrays are computed analogously from the top of the parent coordinate
system downward. Taking `min(lefts[colspan])`, `max(rights[colspan])`,
`min(bottoms[rowspan])`, and `max(tops[rowspan])` gives the bounding extent of
exactly the spanned cells, including any gaps internal to a multi-cell span.

### PO6 and PO7

The `bbox is not None` branch returns before reading GridSpec state, so
constrained layout can continue to install its solved bbox. Separately,
`subfigures` still passes `wspace` and `hspace` to `GridSpec`, preserving the
values consumed by constrained-layout margin logic.

### PO8 and PO9

The V2 change does not alter any public signatures or return shapes. The proof
uses the ordinary layout domain named in `SPEC.md`: positive dimensions,
positive ratio sums, and nonzero denominators. F4 records the out-of-domain
residual risk instead of silently proving over it.

## Adequacy Check

The formal English claims in `FORMAL_SPEC_ENGLISH.md` match the intent entries
in `INTENT_SPEC.md`: the proof covers explicit subfigure spacing, zero default
spacing, generic GridSpec compatibility, span extents, and constrained-layout
override. The V1-specific mismatch is recorded as F2 and repaired in V2.

## Machine-Check Commands Not Run

```sh
kompile fvk/mini-subfigure-layout.k --backend haskell
kast --backend haskell fvk/subfigure-layout-spec.k
kprove fvk/subfigure-layout-spec.k
```

Expected outcome after installing and running the K toolchain: `kprove` reduces
the claims to `#Top`. Until that is run, this remains a constructed proof, not a
machine-checked proof.
