# Spec Audit

| Formal obligation | Intent entry | Verdict | Notes |
|---|---|---|---|
| Weighted fit succeeds over non-empty active list when every active estimator supports `sample_weight`. | Intent 1, 2, 3, 4 | pass | This directly addresses the reported crash and preserves support checking for active estimators. |
| Reported `lr=None`, `rf` active weighted fit uses only `rf`. | Intent 1, 2, 4 | pass | This is the prompt's reproduction reduced to routing behavior. |
| Active estimator without `sample_weight` support raises unsupported-estimator error. | Intent 3 | pass | Preserves public `test_sample_weight` behavior for active estimators. |
| All dropped estimators raise all-dropped error. | Intent 6 | pass | Preserves public `test_set_estimator_none` behavior under valid names. |
| No-sample-weight fit skips support check and fits active estimators. | Intent 1, 4 | pass | Frames existing non-weighted dropped-estimator behavior. |
| `named_estimators_` names exactly the fitted active estimators. | Intent 5 | pass | Public docs describe access to fitted estimators, not dropped entries or misaligned names. |
| Existing estimator-list, weights-length, and name validations are framed. | Intent 7 | pass with scope note | The `.k` model focuses on the active-estimator routing core; `PROOF_OBLIGATIONS.md` tracks this as a frame obligation against the source diff. |

No formal-English obligation is legacy-derived without public evidence. The
old `AttributeError` is marked as a symptom in `FINDINGS.md`, not preserved.
