# FVK Specification: axes_grid1 inset locator renderer fallback

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were executed.

## Unit Under Audit

- Production file: `repo/lib/mpl_toolkits/axes_grid1/inset_locator.py`
- Function: `AnchoredLocatorBase.__call__(self, ax, renderer)`
- Public entry points using this locator base:
  - `inset_axes(...)` via `AnchoredSizeLocator`
  - `zoomed_inset_axes(...)` via `AnchoredZoomLocator`

## Intent Contract

For an `AnchoredLocatorBase` instance installed as an axes locator, a call
`locator(ax, renderer)` must return a transformed bounding box for `ax`.

The in-domain inputs are:

- `ax` is a Matplotlib axes associated with a figure.
- `renderer` is either a renderer object or `None`.
- If `renderer is None`, `ax.figure._get_renderer()` returns a renderer object
  with the renderer methods used by the locator path, including
  `points_to_pixels`.
- Existing inset arguments, anchoring boxes, transforms, and sizes satisfy the
  documented `inset_axes` / `zoomed_inset_axes` preconditions.

Required behavior:

- If `renderer` is not `None`, keep the existing behavior and use that renderer.
- If `renderer is None`, derive the effective renderer from `ax.figure` before
  calling any renderer-consuming `OffsetBox` / locator methods.
- Set `self.axes = ax` as before.
- Compute `get_window_extent(effective_renderer)`,
  `get_offset(..., effective_renderer)`, and return the resulting
  `TransformedBbox`.
- Do not require `self.figure` to be set on the locator object.
- Do not change the public signatures or return types of inset locator APIs.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | issue reproduction | `axins = inset_axes(ax, width=1.3, height=0.9)` followed by inline display raises `AttributeError: 'NoneType' object has no attribute '_get_renderer'` | Creating and displaying an axes-grid inset axes in the documented style should not fail during rendering. | Encoded in PO-001 and PO-002. |
| E-002 | issue expected outcome | The user expected "to add an empty box towards the top right of the first subplot" | The locator should return a bbox rather than aborting before the inset can be positioned. | Encoded in PO-001. |
| E-003 | public hints | Inline backend applies tight bbox behavior; `_tight_bbox.adjust_bbox` calls the axes locator with `renderer=None`. | `renderer=None` is an in-domain call path for axes locators during tight-bbox output. | Encoded in PO-002. |
| E-004 | public hints | "get_window_extent should work" and the problem is missing renderer plumbing for the locator. | The fix should make `get_window_extent` and subsequent renderer users receive a valid renderer. | Encoded in PO-002 and PO-004. |
| E-005 | public hints | "Just do `renderer = ax.figure._get_renderer()` since axes have to have figures." | `ax.figure` is the intended renderer fallback source, not mutating `axes_locator.figure`. | Encoded in PO-002 and PO-003. |
| E-006 | source: `_tight_bbox.adjust_bbox` | `ax.apply_aspect(locator(ax, None))` | Formal model must include the `None` renderer case. | Encoded in PO-002. |
| E-007 | source: `offsetbox.OffsetBox.get_window_extent` | If `renderer is None`, it falls back to `self.figure._get_renderer()`. | Passing `None` into this path is unsafe for locators that are not figure-owned artists. | Finding F-001. |
| E-008 | source: `AnchoredSizeLocator.get_bbox` and `AnchoredOffsetbox.get_offset` | Both require renderer methods such as `points_to_pixels`. | Fallback must happen before both extent and offset calculations. | Encoded in PO-004. |
| E-009 | source: `inset_locator.py` | `AnchoredSizeLocator` and `AnchoredZoomLocator` share `AnchoredLocatorBase.__call__`. | A base-class fallback covers both public anchored inset APIs. | Encoded in PO-006. |

## Formal Scope

The formal model abstracts away numeric bbox arithmetic and transform internals.
It keeps the observable property that matters for this issue: whether the
locator reaches its bbox result with a non-`None` effective renderer and without
requiring `self.figure`.

Out of scope:

- The exact pixel coordinates of the returned bbox.
- Renderer construction internals.
- Invalid axes, invalid transforms, invalid sizes, or invalid locations already
  outside the documented API contract.
- Termination proof for Matplotlib renderer construction.

## Verdict

V1 satisfies the intent contract: the effective renderer is resolved from
`ax.figure` when the caller passes `None`, and that happens before
`get_window_extent` and `get_offset`. No additional production source change is
justified by the FVK audit.
