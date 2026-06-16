# Public Evidence Ledger

Status: constructed for FVK audit; not machine-checked.

| ID | Source | Public evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt/issue | "IterativeImputer has no parameter `fill_value`" | Add `fill_value` to the public `IterativeImputer` constructor and estimator parameter set. | Encoded in O-001. |
| E-002 | prompt/issue | "`initial_strategy` ... Same as the strategy parameter in SimpleImputer" | The initialization strategy delegates to `SimpleImputer` semantics. | Encoded in O-002. |
| E-003 | prompt/issue | "When strategy == `constant`, fill_value is used to replace all occurrences of missing_values" | For `initial_strategy="constant"`, forward the user value to the internal `SimpleImputer`. | Encoded in O-002 and O-003. |
| E-004 | prompt/issue | "If left to the default, fill_value will be 0 when imputing numerical data" | Preserve default behavior by passing `None`, letting `SimpleImputer` choose the default. | Encoded in O-004. |
| E-005 | prompt/issue | "please also allow `np.nan` as `fill_value`" | Do not reject `np.nan`, and do not treat it as an invalid feature statistic in the constant strategy. | Encoded in O-003. |
| E-006 | prompt/issue | "for optimal compatibility with decision tree-based estimators" | Estimator-specific `np.nan` support is a downstream capability, not an `IterativeImputer` validation failure. | Encoded as assumption D-002. |
| E-007 | prompt discussion | Passing `SimpleImputer(...)` as `initial_strategy` currently raises and was described as a suggestion to implement. | Do not broaden this repair to accepting arbitrary imputer instances. | Encoded as out-of-scope decision. |
| E-008 | implementation | V1 stores `self.fill_value` and passes it to `SimpleImputer(..., fill_value=self.fill_value)`. | Candidate implementation fact used in the proof, not independent intent. | Checked by O-001 and O-002. |
| E-009 | implementation | V1 uses all feature indices for `initial_strategy == "constant"` before dropping invalid statistics. | Candidate implementation fact used to discharge `np.nan` compatibility. | Checked by O-003. |

