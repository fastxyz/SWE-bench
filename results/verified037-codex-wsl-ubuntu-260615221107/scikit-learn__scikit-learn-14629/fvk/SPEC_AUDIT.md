# Spec Audit

Status: constructed, not machine-checked.

| Formal obligation | Intent match | Audit result |
| --- | --- | --- |
| Fitted `MultiOutputClassifier` has `classes_`. | Matches E5: all classifiers should store `classes_` when fitted. | Pass |
| `classes_` is a list aligned with fitted per-output estimators. | Matches E4 and E6: use `estimators_[i].classes_`, like `ClassifierChain`. | Pass |
| `cross_val_predict(..., method='predict_proba')` can index `estimator.classes_[i_label]` for list predictions. | Matches E1, E2, E3, and E7. | Pass |
| Successful `partial_fit` also sets `classes_`. | Entailed by E5's fitted-classifier contract and preserves existing delegated incremental fitting. | Pass |
| Domain assumes wrapped classifiers expose `classes_` after fitting. | Matches E5 and the scikit-learn classifier convention; no public evidence requires supporting classifier-like estimators that violate it. | Pass |

No formal-English obligation is candidate-derived without public support. No
SUSPECT legacy behavior is preserved: the reported `AttributeError` is treated
as the defect to remove.
