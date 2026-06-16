# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`cross_val_predict(method='predict_proba')` with a `MultiOutputClassifer`" | The audited path is `cross_val_predict` with list-valued probability predictions from `MultiOutputClassifier`. | Encoded in SPEC and K claim CVP. |
| E2 | prompt | "Expected Results: Array with prediction probabilities." | The reported call should return probabilities, not fail due to missing fitted metadata. | Encoded in SPEC and K claim CVP. |
| E3 | prompt | "Actual Results: `AttributeError: 'MultiOutputClassifier' object has no attribute 'classes_'`" | Missing `classes_` is the legacy symptom to remove, not behavior to preserve. | Finding F-1. |
| E4 | prompt | "To obtain the `classes_` attribute of a `MultiOutputClassifier`, you need `mo_clf.estimators_[i].classes_` instead." | The correct observable `classes_` is indexed per output and aligned with `estimators_`. | Encoded in PO-1 through PO-3. |
| E5 | public hint | "All classifiers should store `classes_` when fitted." | `MultiOutputClassifier` must expose `classes_` after successful fit; successful `partial_fit` is also a fitted state. | Encoded in PO-1 and PO-4. |
| E6 | public hint | "add `classes_` to `MultiOutputClassifier` like it is in `ClassifierChain`" | Use the established list-of-per-estimator-classes pattern. | Encoded in SPEC and K claims. |
| E7 | source | `_fit_and_predict` indexes `estimator.classes_[i_label]` for list predictions. | `classes_` must support per-output indexing for every prediction list entry. | Encoded in PO-3. |
| E8 | source | `predict_proba` returns `[estimator.predict_proba(X) for estimator in self.estimators_]`. | The prediction list order is the estimator order. | Encoded in PO-2 and PO-3. |
| E9 | source | `ClassifierChain.fit` sets `self.classes_ = [estimator.classes_ ...]`. | Established local pattern for per-output classifiers. | Supports V1 shape. |
