# Intent Spec

Status: intent-only, written from public issue text, source comments/docstrings,
and scorer API documentation before accepting V1 behavior.

## Required Behavior

I1. `HistGradientBoostingClassifier.fit(X, y)` with string class labels and
early stopping enabled must not fail because the early-stopping scorer compares
mixed internal and public target representations.

I2. In scorer-based early stopping (`scoring != 'loss'`), the `y` argument
passed to `self.scorer_(self, X, y)` must be in the same public label
representation returned by classifier prediction methods. For classifiers this
means mapping internal class-code targets back through `classes_`.

I3. The training loop and `scoring='loss'` path must continue to use encoded
classification targets, because the hist-gradient-boosting loss functions and
gradient updates operate on numeric class codes.

I4. Regressor behavior must be preserved. Regression targets are not label
encoded and must pass through the scorer unchanged.

I5. Both early-stopping scoring sites are in scope: the initial score before
the first boosting iteration and the score computed after each subsequent
iteration. Both training-subset scoring and validation scoring are in scope.

I6. The fix must not change public estimator signatures, scorer signatures,
prediction output shape, or score array semantics.

## Domain

D1. This audit covers the scorer-based early-stopping path of
`BaseHistGradientBoosting._check_early_stopping_scorer`, reached when
`n_iter_no_change` enables early stopping and `scoring != 'loss'`.

D2. For `HistGradientBoostingClassifier`, `y` has already been transformed by
`LabelEncoder.fit_transform` and cast to `Y_DTYPE`. Each target value is an
integer-valued class code in `0..len(classes_) - 1`.

D3. For `HistGradientBoostingRegressor`, `y` is the regression target vector
and has no class-code/public-label distinction.

D4. This is a partial-correctness audit of the target-representation boundary.
It does not prove tree training quality, convergence, or termination.
