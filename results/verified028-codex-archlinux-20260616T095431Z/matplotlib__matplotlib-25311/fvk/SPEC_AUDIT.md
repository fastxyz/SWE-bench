# Spec Audit

Status: constructed for FVK audit; not machine-checked.

| Claim | Intent Coverage | Verdict |
| --- | --- | --- |
| C-001 `DRAGGABLE-GETSTATE-NO-CANVAS` | Matches I-001/I-002/I-003: pickling fails because a live canvas is reachable; helper state must remove it. | PASS |
| C-002 `DRAGGABLE-SETSTATE-CANVAS-DEFAULT` | Supports I-004 by making restored helpers safe and able to resolve a new canvas later. | PASS |
| C-003 `DRAGGABLE-CANVAS-LAZY-RESTORE` | Supports I-004 and the existing figure pickle design: figures can be detached from one canvas and attached to another. | PASS |
| C-004 `DRAGGABLE-BLIT-SAFE-WHEN-NO-CANVAS` | Supports I-003/I-004 by preventing restored or detached helpers from assuming the original backend's blitting support. | PASS |
| C-005 `FIGURE-PICKLE-WITH-DRAGGABLE` | Directly matches I-001 and I-002 for both public draggable helper producers. | PASS |

No claim over-preserves the observed buggy behavior. The old behavior
`TypeError: cannot pickle 'FigureCanvasQTAgg' object` is classified as the
reported symptom, not as a compatibility requirement.
