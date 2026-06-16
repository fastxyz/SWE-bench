# Spec Audit

Status: constructed for FVK audit; not machine-checked.

| Formal item | Public-intent match | Result |
| --- | --- | --- |
| Claim 1: constructor-order tuple dash forwarding | Matches E1-E4 and E8-E9. The reproduction constructs rectangles with tuple linestyles and linewidth in the constructor. | PASS |
| Claim 2: post-init tuple dash forwarding | Matches E1 and E8. The bug summary says "when setting the linestyle on a patch object," not only during construction. | PASS |
| Claim 3: non-zero offset is not zeroed | Matches E1-E4 and E6-E7. The issue specifically rejects overlapping phases caused by ignored offsets. | PASS |
| Claim 4: invisible-patch frame behavior | Matches the preservation requirement in `INTENT_SPEC.md`; no public evidence suggests changing invisible patch drawing. | PASS |
| Use of `Line2D` storage/scaling convention | Matches E4 and source evidence E9. It is not candidate-derived: the public expected outcome names `Line2D` behavior. | PASS |
| Rejection of legacy "Patch has traditionally ignored the dashoffset" behavior | Matches E10 as SUSPECT legacy evidence conflicting with E1-E7. | PASS |
| Exclusion of backend pixel rasterization from the proof | The public issue and source localization are satisfied by forwarding the correct offset to `gc.set_dashes`; backend rendering is a residual trusted component. | PASS WITH BOUNDARY |
| No warning or compatibility shim | Matches E7. The public issue discussion classifies reliance on ignored non-zero offsets as not worth preserving. | PASS |

No required public behavior is marked fail or ambiguous. The only boundary is
that the mini model proves dash-offset forwarding, not backend pixel rendering.
That boundary does not block the code decision because the pre-fix failure is
localized to the draw-time zeroing of `_dash_pattern[0]`, and V1 removes that
zeroing.
