# Spec Audit

Status: constructed for FVK audit; not machine-checked.

| Formal item | Intent item(s) | Result | Notes |
| --- | --- | --- | --- |
| C1: `drawedges=False` selects empty | Intent 6 | Pass | Preserves existing documented behavior. |
| C2: `extend='neither'` selects `range(1, N - 1)` | Intent 5 | Pass | Non-extended exterior edges are drawn by the outline, not dividers. |
| C3: `extend='min'` selects `range(0, N - 1)` | Intent 2, 4 | Pass | Includes the minimum extension/body join and preserves the non-extended maximum side. |
| C4: `extend='max'` selects `range(1, N)` | Intent 2, 4 | Pass | Includes the maximum extension/body join and preserves the non-extended minimum side. |
| C5: `extend='both'` selects `range(0, N)` | Intent 2, 3 | Pass | Directly addresses the reported missing extremity dividers. |
| PO6: orientation is a frame condition for row selection | Intent 7, ledger E3/E8 | Pass | `_mesh()` swaps coordinate columns for horizontal orientation but still emits one row per long-axis boundary. |
| API compatibility frame | Intent 7 | Pass | No public signature, accepted value, return type, or dispatch protocol changes. |

No formal-English obligation is candidate-only or legacy-derived.  The only
legacy behavior preserved is the non-extended end exclusion, which is supported
by the outline responsibility in the current colorbar geometry and by the issue
scope.
