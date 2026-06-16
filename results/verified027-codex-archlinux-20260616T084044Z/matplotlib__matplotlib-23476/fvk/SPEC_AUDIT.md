# Spec Audit

Status: adequacy gate for the formal claims; constructed, not machine-checked.

| Formal claim | Intent coverage | Verdict |
| --- | --- | --- |
| `GETSTATE-HIDPI-LOGICAL` | Matches E1/E5: high-DPI scaled runtime DPI must not become permanent pickle DPI. | Pass |
| `GETSTATE-RATIO-ONE-PRESERVES-CURRENT-DPI` | Matches ordinary frame condition derived from public API compatibility and the absence of high-DPI intent when ratio is 1. | Pass |
| `SETSTATE-RESYNCS-DPI-TRANSFORM` | Matches E9/E10: `_dpi` and `dpi_scale_trans` are both serialized state, so normalized `_dpi` requires transform consistency after load. | Pass |
| `ROUNDTRIP-HIDPI-SAME-RATIO-IDEMPOTENT` | Matches E2 expected output: repeated same-backend cycles keep live DPI at 200.0 in the reported case. | Pass |
| `ROUNDTRIP-RATIO-ONE-PRESERVES-DPI` | Matches frame condition O2 and avoids overusing `_original_dpi`. | Pass |
| `ROUNDTRIP-HIDPI-LOAD-RATIO-ONE-USES-LOGICAL-DPI` | Entailed by E5 and backend-neutral behavior: if no high-DPI backend reattaches, no ratio should be reapplied. | Pass |

## Audit Notes

The formal spec intentionally does not preserve the pre-fix actual sequence
`200.0, 400.0, 800.0, ...`; that output is SUSPECT legacy behavior because the
issue identifies it as the bug.

The spec does not claim total correctness or runtime absence of every possible
overflow. It proves that the repeated multiplication mechanism causing the
reported overflow is removed from the modeled high-DPI pickle/load path.

The integer numeric model is adequate for the reported ratio-2 doubling defect,
but a future machine-checked proof over non-integer ratios would need a richer
numeric theory.
