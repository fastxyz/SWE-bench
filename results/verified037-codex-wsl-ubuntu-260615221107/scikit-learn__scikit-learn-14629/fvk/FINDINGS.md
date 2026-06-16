# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F-1: Reported AttributeError Is Removed By V1

Input:

`cross_val_predict(MultiOutputClassifier(base_classifier), X, Y, cv=5,
method='predict_proba')`, where fitting succeeds and the base classifier exposes
`classes_`.

Observed in pre-fix code:

`MultiOutputClassifier.fit` populated `estimators_` but did not populate
`classes_`. `_fit_and_predict` then evaluated `estimator.classes_[i_label]` for
list-valued predictions and raised `AttributeError`.

Expected:

The fitted `MultiOutputClassifier` exposes a per-output `classes_` list, so the
probability prediction path can enforce prediction-column order.

V1 status:

Confirmed by PO-1 through PO-3. `MultiOutputClassifier.fit` delegates to the
existing fit path, then sets `self.classes_` from every fitted
`estimator.classes_` in `self.estimators_`.

Classification: fixed code bug.

## F-2: `partial_fit` Must Preserve The Same Fitted Classifier Contract

Input:

Successful `MultiOutputClassifier.partial_fit(X, y, classes=classes)` with a
base estimator that supports incremental fitting and exposes `classes_`.

Observed in pre-fix code:

The inherited delegated method populated or updated `estimators_` but left
`MultiOutputClassifier.classes_` absent.

Expected:

The public hint says all classifiers should store `classes_` when fitted.
Successful incremental fitting is a fitted state, so `classes_` should be
available there too.

V1 status:

Confirmed by PO-4 and PO-5. V1 keeps delegated availability via
`@if_delegate_has_method('estimator')`, delegates to the shared implementation,
then sets `classes_` from fitted estimators.

Classification: fixed completeness issue relative to public classifier
contract.

## F-3: No `cross_val_predict` Special Case Is Needed

Input:

The `_fit_and_predict` list branch receives list-valued probabilities from
`MultiOutputClassifier.predict_proba`.

Observed in V1:

The consumer still reads `estimator.classes_[i_label]`; the producer now exposes
that list.

Expected:

The issue points out the missing per-output source, and the public hint locates
the bug in `MultiOutputClassifier`, not in `_validation.py`.

V1 status:

Confirmed by PO-3 and PO-7. Leaving `_validation.py` unchanged is justified.

Classification: no source change needed.

## F-4: Base Estimators Without `classes_` Are Outside This Fix's Domain

Input:

A wrapped classifier-like estimator whose successful `fit` does not expose
`classes_`.

Observed in V1:

The list comprehension that sets `self.classes_` would raise from the wrapped
estimator.

Expected:

No public issue evidence requires supporting classifiers that violate the
scikit-learn fitted classifier contract. The public hint explicitly states that
all classifiers should store `classes_` when fitted.

V1 status:

Accepted as an intent-derived precondition, recorded in PO-6.

Classification: out-of-domain / no code change.

## F-5: Compatibility Surface Is Preserved

Input:

Existing public calls to `MultiOutputClassifier.fit`, delegated
`partial_fit`, `predict_proba`, and `MultiOutputRegressor`.

Observed in V1:

`fit` and `partial_fit` signatures remain unchanged. `partial_fit` remains
delegate-gated. `MultiOutputRegressor` is untouched. `predict_proba` retains its
existing missing-method `ValueError`.

Expected:

The patch should add fitted metadata without broad API or behavior changes.

V1 status:

Confirmed by PO-5 and PO-7 and by `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Classification: compatibility confirmed.

## F-6: Proof Is Constructed, Not Machine-Checked

Input:

The FVK `.k` artifacts in this workspace.

Observed:

The environment forbids running K commands, tests, or Python. The proof is a
constructed symbolic proof only.

Expected:

Run the emitted `kompile`, `kast`, and `kprove` commands later before treating
the proof as machine-checked or removing any tests.

V1 status:

Residual verification caveat, not a source-code bug.

Classification: proof/tooling caveat.
