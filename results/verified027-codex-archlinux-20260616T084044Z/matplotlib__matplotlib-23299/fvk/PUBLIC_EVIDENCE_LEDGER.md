# Public Evidence Ledger

Constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "get_backend() clears figures from Gcf.figs if they were created under rc_context" | `get_backend()` must not remove existing managers from `Gcf.figs` in the reported stale-sentinel state. | Encoded by PO-1 and claim 1. |
| E2 | prompt | "The figure should not be missing from Gcf." | The observable `Gcf.figs` collection is framed across the `get_backend()` call. | Encoded by PO-1 and claim 1. |
| E3 | prompt | "`plt.close(fig2)` doesn't work because `Gcf.destroy_fig()` can't find it" | The fix must preserve the manager-to-figure relationship in `Gcf.figs`, not merely preserve the `Figure` object. | Encoded as preservation of the `Figs` collection abstraction. |
| E4 | prompt hint | "rcParams['backend'] in the auto-sentinel ... stashed by rc_context ... context manager sets it back to the sentinel ... get_backend() re-resolves" | Root cause is re-resolution of a stale sentinel after backend selection already happened. | Encoded by the loaded-backend stale-sentinel claim. |
| E5 | source/docstring | `get_backend()` returns `rcParams['backend']`. | The formal unit under audit is global `RcParams.__getitem__("backend")` as reached by `get_backend()`. | Encoded by all claims. |
| E6 | source/docstring | `pyplot.switch_backend` says it closes all open figures and its implementation calls `close("all")`. | Real backend switching may clear figures; the repair should avoid unnecessary switching, not remove switch cleanup. | Encoded by PO-2 and the `switchBackend` rule. |
| E7 | source code | `switch_backend` stores the selected backend in pyplot state and `matplotlib.backends.backend`. | Once pyplot has a loaded backend, that selection is the authoritative current backend. | Encoded by PO-1 and compatibility audit C2. |
| E8 | public tests/source | Existing code distinguishes global `rcParams` from standalone `RcParams` when resolving the sentinel. | Non-global `RcParams({"backend": sentinel})["backend"]` must remain non-resolving. | Encoded by PO-4 and compatibility audit C3. |
