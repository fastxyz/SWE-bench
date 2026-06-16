# Formal Spec English

This file paraphrases the nontrivial K claims in `hgb-scorer-spec.k`.

## HGB-GET-Y-BASE

For the base hist-gradient-boosting scorer boundary, `_get_y_for_scorer(y)`
returns the exact same target vector `y`. This covers regressors and any shared
base behavior that does not define a classifier `classes_` mapping.

## HGB-GET-Y-CLASSIFIER

For a classifier with class-label vector `classes_` and an internal encoded
target vector `codes`, `_get_y_for_scorer(codes)` returns the vector obtained by
replacing each code `i` with `classes_[i]`. The claim requires every code to be
a valid index into `classes_`.

## HGB-SCORER-CLASSIFIER-VAL

When `_check_early_stopping_scorer` is called for a classifier with validation
data enabled, the training scorer call receives decoded training labels and the
validation scorer call receives decoded validation labels.

## HGB-SCORER-CLASSIFIER-NOVAL

When `_check_early_stopping_scorer` is called for a classifier with validation
data disabled, the training scorer call receives decoded training labels and no
validation scorer call is made.

## HGB-SCORER-BASE-VAL

When `_check_early_stopping_scorer` is called for base/regression behavior with
validation data enabled, the training and validation scorer calls receive their
original target vectors unchanged.

## HGB-SCORER-BASE-NOVAL

When `_check_early_stopping_scorer` is called for base/regression behavior with
validation data disabled, the training scorer call receives its original target
vector unchanged and no validation scorer call is made.

## Frame Conditions

The formal claims do not alter the loss-scoring path, tree training state,
`classes_`, prediction output, `train_score_`/`validation_score_` append
semantics, or public method signatures. They model only the target vector
passed across the scorer boundary.
