# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Public inset creation/rendering does not abort

For an inset axes created by `mpl_toolkits.axes_grid1.inset_locator.inset_axes`,
the locator path used during tight-bbox output must return a bbox instead of
raising the reported `AttributeError`.

Evidence: E-001, E-002.

## PO-002: `renderer=None` is an in-domain locator call

When `AnchoredLocatorBase.__call__(ax, renderer)` receives `renderer is None`,
it must derive an effective renderer from `ax.figure._get_renderer()` before any
renderer-consuming operation.

Evidence: E-003, E-005, E-006.

## PO-003: Provided-renderer behavior is preserved

When `renderer` is not `None`, `AnchoredLocatorBase.__call__` must keep using
the provided renderer and otherwise follow the existing computation.

Evidence: public API compatibility and source frame condition.

## PO-004: All renderer consumers receive the effective renderer

The renderer passed to `get_window_extent` and `get_offset` must be non-`None`.
For `AnchoredSizeLocator` and `AnchoredZoomLocator`, this also means their
`get_bbox` implementations can use `points_to_pixels`.

Evidence: E-004, E-008.

## PO-005: No dependency on `self.figure`

The locator must not require its own `figure` attribute to be set, because it is
installed as an axes locator rather than added as a normal figure-owned artist.

Evidence: E-004, E-005, E-007.

## PO-006: Shared-base coverage

The fix must cover every public anchored inset API using
`AnchoredLocatorBase.__call__`, specifically `AnchoredSizeLocator` and
`AnchoredZoomLocator`.

Evidence: E-009.

## PO-007: Domain honesty

The proof assumes a real axes object with an associated figure and a valid
figure renderer. It must not claim correctness for manual calls with an invalid
axes object or for renderer construction failures outside this locator's
contract.

Evidence: Matplotlib axes locator API shape and `Axes.get_tightbbox` using
`self.figure._get_renderer()` for omitted renderers.

## PO-008: Honesty gate

The proof must be labeled constructed, not machine-checked, and no test-removal
recommendation may be acted on in this benchmark workspace.

Evidence: user task instructions and FVK `verify.md` honesty gate.
