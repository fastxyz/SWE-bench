# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item | Result | Notes |
| --- | --- | --- | --- |
| `MI-ARRAY-DEFAULT-LEVEL-DTYPE` | I1, I2, I3, B1, B3, B4 | pass | Matches public intent that xarray's stored original dtype controls default level-coordinate materialization. |
| `MI-ARRAY-EXPLICIT-DTYPE` | I4, B2 | pass | Preserves NumPy protocol behavior for explicit dtype requests. |
| `STACKED-LEVEL-VALUES-DTYPE` | I1, E2, B4 | pass | Generalizes the reported `int32` example to any castable original level dtype. |
| `MI-ARRAY-NONLEVEL-DELEGATES` | B5, E6 | pass | Confirms the unchanged branch remains delegated to the base adapter. |
| Side condition S1 | Domain | pass | The public issue concerns existing stacked coordinates, so missing pandas levels are outside the intended input domain. |
| Side condition S2 | Domain | pass | The original coordinate dtype is expected to be a valid cast target for values created from that coordinate. |
| Side condition S3 | FVK honesty gate | pass | The task forbids execution, so proof and machine commands are constructed only. |

No formal item is marked fail or ambiguous. The audit therefore supports
confirming V1 unchanged, subject to the constructed-not-machine-checked caveat.

