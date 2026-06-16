# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or Matplotlib tests were run.

## Claims Proved by Construction

- C-001: `AnchoredLocatorBase.__call__(ax, renderer)` returns a bbox on the
  provided-renderer path while preserving existing behavior.
- C-002: `AnchoredLocatorBase.__call__(ax, None)` resolves
  `ax.figure._get_renderer()` and then returns a bbox without requiring
  `self.figure`.
- C-003: The same proof covers both `AnchoredSizeLocator` and
  `AnchoredZoomLocator` because they inherit the audited `__call__`.

These correspond to PO-001 through PO-006.

## Adequacy Gate

The public intent requires the reproduction using
`mpl_toolkits.axes_grid1.inset_locator.inset_axes` to render under a tight-bbox
caller instead of raising an `AttributeError`. The formal claims in
`inset-locator-spec.k` paraphrase exactly that renderer-resolution property:
`renderer=None` must be converted to the axes figure renderer before extent and
offset calculations.

The claims intentionally do not specify exact bbox coordinates. The issue is a
renderer plumbing failure, and exact geometry is governed by existing
Matplotlib transform and offsetbox code. This abstraction preserves the
property that distinguishes the failing and passing programs: whether the
renderer-sensitive path receives `None` or a valid renderer.

## Symbolic Proof Sketch

Case 1: `renderer` is provided.

1. Enter `AnchoredLocatorBase.__call__(ax, renderer)` with `renderer != None`.
2. The fallback branch is skipped, so the effective renderer is the provided
   renderer. This discharges PO-003.
3. `self.axes = ax` executes as in the previous implementation.
4. `self.get_window_extent(renderer)` receives a non-`None` renderer, so
   `OffsetBox.get_window_extent` does not consult `self.figure`.
5. `self.get_offset(..., renderer)` receives the same non-`None` renderer.
6. The method returns `TransformedBbox(bbox_canvas, ax.figure.transSubfigure.inverted())`.

Case 2: `renderer is None`.

1. Enter `AnchoredLocatorBase.__call__(ax, None)` on an in-domain axes object.
2. V1 executes `renderer = ax.figure._get_renderer()`. By PO-007, this yields a
   valid renderer.
3. `self.axes = ax` executes as before.
4. `self.get_window_extent(renderer)` receives a non-`None` renderer. Therefore
   `OffsetBox.get_window_extent` does not execute its unsafe fallback through
   the locator's unset `self.figure`. This discharges F-001.
5. `AnchoredSizeLocator.get_bbox` / `AnchoredZoomLocator.get_bbox` and
   `AnchoredOffsetbox.get_offset` receive the same non-`None` renderer, so their
   `points_to_pixels` calls are defined. This discharges F-002 and PO-004.
6. The method returns the transformed bbox as in the provided-renderer case.

Because both public anchored locator subclasses share this base implementation,
the constructed proof discharges PO-006.

## Machine-Check Commands Not Run

The commands that would be used in an execution-enabled environment are:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell inset-locator-spec.k
kprove inset-locator-spec.k
```

Expected result after machine checking: `#Top` for all claims. This expectation
is not asserted as a completed machine check in this workspace.

## Test Guidance

No tests are redundant until the proof is machine-checked. Existing tests should
be kept. Useful future tests, in an execution-enabled environment, would cover:

- The issue reproduction under a tight-bbox print/save path.
- Direct locator invocation with `locator(ax, None)`.
- A provided-renderer invocation to guard the frame condition.
- Both `inset_axes` and `zoomed_inset_axes`, because both share the audited base.

## Residual Risk

- The proof is partial correctness only: if the method returns, the renderer
  plumbing property holds. It does not prove renderer construction termination.
- The mini-K semantics abstracts Matplotlib's real renderer, bbox, and transform
  implementation.
- The proof is constructed, not machine-checked.
