# Public Evidence Ledger

Status: constructed from allowed inputs only.

| ID | Source | Quoted Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Starting in matplotlib 3.1.0 it is no longer possible to invert a log axis using its limits." | Reversed explicit limits must invert a log axis. | Encoded in SPEC and K claims. |
| E2 | `benchmark/PROBLEM.md` | `ax.set_yscale(yscale)` then `ax.set_ylim(y.max(), y.min())` for `yscale in ('linear', 'log')` | The required input class is finite positive unequal limits with first limit greater than second. | Encoded in PO1. |
| E3 | `benchmark/PROBLEM.md` | "I would expect the yaxis to be inverted for both the ``\"linear\"`` and the ``\"log\"`` scale." | Log scale must match the linear-scale orientation semantics for reversed explicit limits. | Encoded in PO1 and PO3. |
| E4 | `repo/lib/matplotlib/axes/_base.py` docs | "The *bottom* value may be greater than the *top* value, in which case the y-axis values will decrease from *bottom* to *top*." | Axis view interval order is the public inversion mechanism. | Encoded in axis-level claim. |
| E5 | `repo/lib/matplotlib/axes/_base.py` docs | "The *left* value may be greater than the *right* value, in which case the x-axis values will decrease from left to right." | Same order-preservation obligation applies to x limits through the same locator. | Compatibility and frame condition. |
| E6 | `repo/lib/matplotlib/axis.py` | `return high < low` in `Axis.get_inverted` | Inversion is determined by the stored interval order. | Encoded in the `isInverted` claim. |
| E7 | `repo/lib/matplotlib/ticker.py` | Base `Locator.nonsingular` calls `mtransforms.nonsingular(..., increasing=False, ...)` | The default locator convention preserves reversed order while avoiding singularities. | Supporting obligation for log locator parity. |
| E8 | `repo/lib/matplotlib/scale.py` | `LogScale.limit_range_for_scale` returns each bound unchanged when it is positive. | For finite positive explicit limits, the log scale clamp is an identity frame condition. | Encoded in PO3. |
| E9 | `repo/lib/matplotlib/ticker.py` | `LogLocator.tick_values` sorts only for tick calculation when `vmax < vmin`. | Tick generation can keep its internal sorted calculation without mutating axis interval order. | Encoded as frame condition. |
| E10 | `benchmark/PROBLEM.md` public hint | "this is fixed by ... too big to backport ... extract ... enough" | A small targeted change is expected; avoid broad refactoring. | Supports keeping V1 narrow. |

