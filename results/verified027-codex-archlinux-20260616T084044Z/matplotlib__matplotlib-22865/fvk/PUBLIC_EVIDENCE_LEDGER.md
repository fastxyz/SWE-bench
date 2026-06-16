# Public Evidence Ledger

Status: constructed for FVK audit; not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | problem | "Colorbar with drawedges=True and extend='both' does not draw edges at extremities" | With `drawedges=True`, `extend='both'` must include both extremity divider lines. | Encoded by PO4, PO5, K claims C4 and C5. |
| E2 | problem | "`drawedges` to True ... separates the colors of the colorbar with black lines" | Divider lines represent color boundaries, including extension/body joins. | Encoded by SPEC required behavior 1-3. |
| E3 | problem reproduction | `ColorbarBase(... orientation='horizontal', drawedges=True)` with a colormap/norm produced by `from_levels_and_colors(..., extend='both')` | Horizontal orientation is in scope; the selection must not depend on vertical-only assumptions. | Encoded by PO6. |
| E4 | public docstring | `drawedges : bool` / "Whether to draw lines at color boundaries." | The implementation must select all intended color-boundary divider segments when enabled. | Encoded by PO2-PO5. |
| E5 | public docstring | `extend : {'neither', 'both', 'min', 'max'}` / "Make pointed end(s) for out-of-range values" | Extension sides are semantic inputs to divider selection. | Encoded by all K claims. |
| E6 | public docstring | `extendrect : bool` says extensions may be triangular or rectangular | The divider selection must be about the extension/body join, not about triangle-only geometry. | Encoded by PO4 and PO5; no code path depends on `extendrect`. |
| E7 | implementation | `_do_extends` outline path follows the outside of extension patches and does not include the base segment between extension and main body. | The missing join line must come from `dividers`, not from the outline. | Encoded by F1 and PO4/PO5. |
| E8 | implementation | `_mesh()` returns row `0` for the minimum main-body boundary and row `N-1` for the maximum main-body boundary; horizontal orientation swaps coordinate columns but keeps row order. | Selecting first/last rows expresses the min/max boundary segments across orientations. | Encoded by PO1 and PO6. |
| E9 | implementation | Previous code selected `np.dstack([X, Y])[1:-1]` for all `extend` values. | Legacy behavior is suspect because it drops both extension/body join boundaries. | Finding F1. |
| E10 | public tests | In-repo tests cover extension shapes and BoundaryNorm colorbars but do not assert `drawedges=True` divider segment endpoints. | No public compatibility obligation requires preserving the missing endpoint-divider behavior. | Encoded by compatibility audit C0. |
