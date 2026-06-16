# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Public intent item | Verdict | Notes |
| --- | --- | --- | --- |
| `IFOREST-DEFAULT-WARM-START` | E3, E7 | Pass | Default `warm_start=False` and old positional fields are preserved. |
| `IFOREST-EXPLICIT-WARM-START` | E1, E2, E3 | Pass | Explicit boolean value is propagated into the constructed estimator state. |
| `IFOREST-POSITIONAL-COMPAT` | E7 | Pass for V2, fail for V1 | V2 appends `warm_start`; V1 inserted it before `n_jobs` and shifted old positional calls. |
| Docstring obligation | E4, E6 | Pass | The `IsolationForest` docstring uses the requested wording. |
| No new fit logic | E2, E5 | Pass | `BaseBagging` already implements the behavior; the code only exposes and forwards the parameter. |

No formal item is based solely on candidate behavior. The only implementation
evidence used is the existing `BaseBagging` storage and `_fit` branch, which is
the mechanism the issue explicitly identified.
