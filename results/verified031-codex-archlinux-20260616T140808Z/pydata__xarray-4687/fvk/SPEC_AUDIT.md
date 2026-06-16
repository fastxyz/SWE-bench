# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent coverage | Verdict | Notes |
|---|---|---|---|
| WHERE-VALUE | E8 | Pass | The issue is metadata-specific; selected values must remain unchanged. |
| WHERE-KEEP-TRUE | E1, E2, E3, E5, E7 | Pass | Data-first attr priority is required for `xr.where(da == 0, -1, da)` where the mask may have no attrs. |
| WHERE-KEEP-FALSE | E6 | Pass | Public hint asks for choice; explicit false is the drop-attrs choice. |
| WHERE-KEEP-NONE | E2, E6, E7 | Pass with compatibility risk | The issue's expected output supports preservation by default; the hint flags breakage risk, mitigated by adding `keep_attrs` and respecting global false. See FVK-F2. |
| WHERE-EXACT-JOIN | E8 and existing source contract | Pass | V2 preserves the original `join="exact"` and `dataset_join="exact"` arguments. |
| First MCVE with scalar `x` and `y` after attr-dropping comparison | E4 | Ambiguous/residual | Top-level `where` cannot infer attrs from the original data once the comparison has dropped them and both choices are scalars. See FVK-F1. |
| Dtype conservation | E10 | Out of scope | The fix does not alter `duck_array_ops.where` dtype promotion. |

Conclusion: V1's source change is adequate for the `xr.where` wrapper
obligations. The residual first-MCVE limitation belongs to comparison attr
propagation, not to the top-level `where` wrapper.
