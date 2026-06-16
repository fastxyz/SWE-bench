# Formal Spec English

Status: constructed, not machine-checked.

K claim `MOC-FIT-SETS-CLASSES`:
For any non-empty list `CS` of per-output class-label arrays, executing the
abstract `MultiOutputClassifier.fit` transition leaves the classifier state with
`estimators_` equal to one fitted estimator per entry of `CS`, and `classes_`
equal to `CS` in the same order.

K claim `MOC-PARTIAL-FIT-SETS-CLASSES`:
For any non-empty list `CS` of per-output class-label arrays, executing the
abstract successful `MultiOutputClassifier.partial_fit` transition leaves the
classifier state with `estimators_` equal to one fitted estimator per entry of
`CS`, and `classes_` equal to `CS` in the same order.

K claim `CVP-PREDICT-PROBA-CAN-INDEX-CLASSES`:
For any non-empty per-output class list `CS` and probability-prediction list
`PREDS` of the same length, the abstract `cross_val_predict(...,
method='predict_proba')` list branch following `MultiOutputClassifier.fit` can
read the classifier's per-output `classes_` list and pass it to the prediction
ordering operation without encountering a missing `classes_` attribute.

Simplification lemma:
Collecting `.classes_` from the abstract estimator list constructed from `CS`
returns exactly `CS`. This is the formal counterpart of the V1 list
comprehension `[estimator.classes_ for estimator in self.estimators_]`.
