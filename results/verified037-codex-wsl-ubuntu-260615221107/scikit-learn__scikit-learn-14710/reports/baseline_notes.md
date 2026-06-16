# Baseline Notes

## Root Cause

`HistGradientBoostingClassifier.fit` encodes classification targets with
`LabelEncoder` before training, so the early-stopping machinery stores
`y_train`, `y_val`, and the small training subset as numeric class codes.
When early stopping uses a scorer instead of the internal loss, the scorer
calls the public prediction API. For classifiers, `predict` returns the
original class labels from `classes_`, not the internal numeric codes.

As a result, scorer-based early stopping compared encoded `y_true` values
against decoded `y_pred` values. With string labels this mixed numeric and
string labels inside metrics such as accuracy, leading to the reported
`TypeError`.

## Changed Files

`repo/sklearn/ensemble/_hist_gradient_boosting/gradient_boosting.py`

Added a private `_get_y_for_scorer` hook on `BaseHistGradientBoosting` that
returns `y` unchanged by default, preserving regressor behavior. The
early-stopping scorer path now passes both training-subset targets and
validation targets through this hook before calling `self.scorer_`.

Overrode `_get_y_for_scorer` in `HistGradientBoostingClassifier` to map the
internally encoded target values back through `self.classes_` before scoring.
This makes scorer inputs consistent with classifier predictions while leaving
the training and loss code on encoded targets.

## Assumptions and Alternatives

I assumed that scorer callables should receive target labels in the estimator's
public representation, matching the labels returned by `predict` and expected
by scikit-learn scorers. This is the standard scorer boundary and is also the
only representation that works consistently for string class labels.

I left `scoring='loss'` unchanged because the loss functions are internal to
hist gradient boosting and operate on the encoded target representation.

I considered converting `y_train` and `y_val` back to original labels
immediately after the train/validation split, but rejected that because the
training loop, gradients, and loss computation require encoded class values.

I also considered checking `hasattr(self, 'classes_')` directly inside
`_check_early_stopping_scorer`, but used a small overridable hook instead so
the shared base method does not need classifier-specific attribute checks.
