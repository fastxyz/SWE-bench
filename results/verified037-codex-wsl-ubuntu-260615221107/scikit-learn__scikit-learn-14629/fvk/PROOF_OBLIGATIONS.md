# Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## PO-1: Fit Produces Fitted Per-Output Estimators

Statement:

After `MultiOutputClassifier.fit(X, y, sample_weight=None)` returns normally,
`self.estimators_` contains one fitted estimator for each output column in `y`.

Evidence:

The existing shared `MultiOutputEstimator.fit` constructs `self.estimators_` by
parallelizing `_fit_estimator(self.estimator, X, y[:, i], sample_weight)` over
`range(y.shape[1])`.

Discharge:

V1 delegates to `super().fit(...)` and does not change this behavior.

Finding links: F-1, F-5.

## PO-2: Fit Sets `classes_` As The Ordered Per-Estimator Class List

Statement:

After normal `MultiOutputClassifier.fit`, `self.classes_[i]` equals
`self.estimators_[i].classes_` for every fitted output index `i`.

Evidence:

V1 executes
`self.classes_ = [estimator.classes_ for estimator in self.estimators_]`.

Discharge:

The list comprehension is order-preserving over `self.estimators_`. This matches
the issue's `estimators_[i].classes_` obligation and the `ClassifierChain`
pattern.

Finding links: F-1.

## PO-3: `cross_val_predict` Can Index The Per-Output Class List

Statement:

When `_fit_and_predict` receives list-valued predictions with length
`n_outputs`, every access to `estimator.classes_[i_label]` is defined and refers
to the class labels for the same output as `predictions[i_label]`.

Evidence:

`MultiOutputClassifier.predict_proba` returns
`[estimator.predict_proba(X) for estimator in self.estimators_]`; V1 sets
`classes_` by iterating over the same `self.estimators_` in the same order.

Discharge:

The producer and metadata lists share the same source order and length.
Therefore `_fit_and_predict` no longer reaches the reported missing-attribute
failure on the audited domain.

Finding links: F-1, F-3.

## PO-4: `partial_fit` Sets `classes_` After Successful Incremental Fit

Statement:

After normal `MultiOutputClassifier.partial_fit`, `self.classes_[i]` equals
`self.estimators_[i].classes_` for every output index `i`.

Evidence:

V1 delegates to `super().partial_fit(...)`, then executes the same ordered list
comprehension used by `fit`.

Discharge:

The public fitted-classifier contract applies to successful incremental fitting
as well. The obligation discharges under the same list-order argument as PO-2.

Finding links: F-2.

## PO-5: Delegated `partial_fit` Availability And Signature Are Preserved

Statement:

Adding a `MultiOutputClassifier.partial_fit` override must not make
`partial_fit` publicly available when the wrapped estimator does not support it,
nor require new arguments.

Evidence:

V1 keeps `@if_delegate_has_method('estimator')` and the inherited signature
`partial_fit(self, X, y, classes=None, sample_weight=None)`.

Discharge:

The public compatibility audit finds no changed caller contract.

Finding links: F-2, F-5.

## PO-6: Wrapped Classifier Contract

Statement:

The proof assumes every successfully fitted wrapped classifier exposes
`classes_`.

Evidence:

The public hint states, "All classifiers should store `classes_` when fitted."

Discharge:

This is an intent-derived precondition, not an implementation-derived escape.
Supporting classifier-like estimators that violate this contract is outside the
reported issue and outside the FVK spec.

Finding links: F-4.

## PO-7: Frame Conditions

Statement:

The patch must not alter unrelated public behavior: `MultiOutputRegressor`,
`cross_val_predict` internals, probability values, or the existing
`predict_proba` missing-method error.

Evidence:

The only source diff is in `repo/sklearn/multioutput.py` inside
`MultiOutputClassifier`; `_validation.py` and `MultiOutputRegressor` are
unchanged.

Discharge:

V1 adds fitted metadata after successful fitting and leaves the listed
unrelated behavior unchanged.

Finding links: F-3, F-5.
