# Public Evidence Ledger

| ID | Source | Quoted or summarized evidence | Obligation |
| --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md` | Reproduction creates `axins = inset_axes(ax, width=1.3, height=0.9)` and fails while printing the figure. | Inset axes must not abort during display. |
| E-002 | `benchmark/PROBLEM.md` | Expected "to add an empty box towards the top right of the first subplot". | Locator must return a bbox for placement. |
| E-003 | public hints | Inline backend applies tight bbox behavior. | Tight-bbox caller behavior is in scope. |
| E-004 | public hints | The issue is renderer plumbing; `get_window_extent` should work. | The locator must supply a renderer to extent calculation. |
| E-005 | public hints | Use `ax.figure._get_renderer()` because axes have figures. | Fallback source is the target axes' figure. |
| E-006 | source | `_tight_bbox.adjust_bbox` calls `locator(ax, None)`. | `renderer=None` is in-domain. |
| E-007 | source | `OffsetBox.get_window_extent(None)` consults `self.figure._get_renderer()`. | Passing `None` is unsafe for non-artist locators. |
| E-008 | source | `get_bbox` and `get_offset` use renderer methods. | Fallback must precede all renderer consumers. |
| E-009 | source | `AnchoredSizeLocator` and `AnchoredZoomLocator` inherit `AnchoredLocatorBase.__call__`. | Base-class fix covers both APIs. |
