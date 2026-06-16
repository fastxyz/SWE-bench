# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | prompt | "Voting estimator will fail at fit if weights are passed and an estimator is None" | `None` estimators are in-domain for voting fit, including weighted fit. | Encoded by `active(ES)` filtering in claims. |
| E2 | prompt | "Because we don't check for an estimator to be `None` in `sample_weight` support" | The support check must skip dropped estimators. | Encoded by `FIT-SAMPLE-WEIGHT-ACTIVE`. |
| E3 | prompt example | `voter.set_params(lr=None); voter.fit(..., sample_weight=...)` | The reported example should fit the remaining estimator and not inspect `lr`. | Encoded by `FIT-REPORTED-EXAMPLE`. |
| E4 | traceback | `AttributeError: 'NoneType' object has no attribute 'fit'` | The old error is the symptom to remove, not behavior to preserve. | Finding F1. |
| E5 | docstring | `estimators_` are "fitted sub-estimators ... that are not `None`" | Fit and fitted collections range over non-dropped estimators. | Encoded by `active(ES)` and `names(active(ES))`. |
| E6 | docstring | `named_estimators_` provides access to fitted sub-estimators by name. | Names must align with the filtered fitted collection. | Encoded by `ok(names(active), names(active))`; Finding F2 drove V2 refactor. |
| E7 | public test | `test_sample_weight` expects a ValueError for an active `KNeighborsClassifier` without sample-weight support. | Active unsupported estimators still raise the existing unsupported-estimator error. | Encoded by `FIT-ACTIVE-UNSUPPORTED`. |
| E8 | public test | `test_set_estimator_none` expects all estimators `None` to raise "All estimators are None..." | All-dropped behavior is preserved. | Encoded by `FIT-ALL-DROPPED`. |
| E9 | public test | `test_set_estimator_none` expects prediction/transform to use only non-`None` estimators and filtered weights. | Existing filtered behavior is the compatibility frame. | Reflected in frame conditions and proof obligations. |
