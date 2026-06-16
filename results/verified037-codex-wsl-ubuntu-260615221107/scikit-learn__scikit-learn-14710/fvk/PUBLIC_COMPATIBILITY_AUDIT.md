# Public Compatibility Audit

## Changed Symbols

C1. `BaseHistGradientBoosting._get_y_for_scorer(self, y)` was added as a
private helper. It is not a public estimator method, not documented, and not a
parameterized user-facing API.

C2. `HistGradientBoostingClassifier._get_y_for_scorer(self, y)` overrides that
private helper to decode internal class codes through `classes_`.

C3. `_check_early_stopping_scorer` now calls the private helper before invoking
`self.scorer_`. Its signature is unchanged.

## Public Callsite and Override Search

Static search found `_get_y_for_scorer` only in
`repo/sklearn/ensemble/_hist_gradient_boosting/gradient_boosting.py`: the base
definition, the classifier override, and the two internal call sites inside
`_check_early_stopping_scorer`.

No public callsite, documented method, estimator constructor signature, scorer
signature, or subclass outside this file needs an update.

## Producer/Consumer Shape

The producer is `_encode_y` for classifiers, which emits integer-valued class
codes after fitting `classes_`. The consumer is the scorer callable, whose
public contract is `(estimator, X, y)`. V1 changes only the representation of
the `y` argument at that boundary from internal codes to public labels.

Prediction outputs, probability outputs, decision-function outputs, and score
array shapes are unchanged.
