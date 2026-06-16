# Public Evidence Ledger

Status: constructed for FVK audit; not machine-checked.

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt | "Unable to pickle figure with draggable legend" | A figure containing a draggable legend must serialize successfully. | Encoded by SPEC S-001 and claim `DRAGGABLE-GETSTATE-NO-CANVAS`. |
| E-002 | prompt | "Same error comes for draggable annotations." | The fix must apply to the common draggable helper, not only `Legend`. | Encoded by SPEC S-002 and producer audit. |
| E-003 | prompt | "`TypeError: cannot pickle 'FigureCanvasQTAgg' object`" | Live backend canvases are forbidden in the reachable pickle state. | Encoded by SPEC S-003 and PO-001/PO-002. |
| E-004 | source comment | `Figure.__getstate__`: "The canvas cannot currently be pickled" and `state.pop("canvas")` | Existing figure-level policy is to remove canvases from pickle state. | Encoded by SPEC S-003; confirms the helper is the extra path. |
| E-005 | source docstring | `_connect_picklable`: "the callback is kept when pickling/unpickling" | Preserving draggable callback state is intended when possible. | Encoded by SPEC S-004 and PO-005. |
| E-006 | public API docs | `Legend.set_draggable` returns `.DraggableLegend`; `Annotation.draggable` returns `.DraggableAnnotation`. | Both public producers must satisfy the same helper invariant. | Encoded by SPEC S-002 and compatibility audit. |
| E-007 | source implementation | `DraggableBase.__init__` stores the live canvas and connects picklable callbacks. | Implementation fact: helper state is on the serialization path and must be sanitized. | Encoded in mini semantics and findings F-001/F-002. |

No hidden tests, evaluator output, internet sources, or upstream patch knowledge
were used.
