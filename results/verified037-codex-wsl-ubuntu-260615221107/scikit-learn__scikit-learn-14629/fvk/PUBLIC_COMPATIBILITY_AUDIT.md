# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed public symbol: `sklearn.multioutput.MultiOutputClassifier.fit`

- Signature remains `fit(self, X, y, sample_weight=None)`, matching the inherited
  public method.
- It delegates to the existing shared implementation for validation,
  sample-weight handling, parallel fitting, and return-state setup.
- It now adds the standard classifier fitted attribute `classes_`.
- No public caller is required to pass new arguments or consume a changed return
  type.

Changed public symbol: `sklearn.multioutput.MultiOutputClassifier.partial_fit`

- Signature remains `partial_fit(self, X, y, classes=None,
  sample_weight=None)`, matching the inherited delegated public method.
- It preserves `@if_delegate_has_method('estimator')`, so availability remains
  conditional on the wrapped estimator.
- It delegates to the existing shared incremental fitting implementation and
  returns `self`.

Producer/consumer compatibility:

- Producer: `MultiOutputClassifier.predict_proba` returns a list in
  `self.estimators_` order.
- Consumer: `model_selection._validation._fit_and_predict` indexes
  `estimator.classes_[i_label]` for list predictions.
- V1 makes the producer's fitted metadata match the consumer's expected shape.

Unaffected public surface:

- `MultiOutputRegressor` still has no `classes_` attribute added by this patch.
- `cross_val_predict` is unchanged.
- The existing `ValueError` from `MultiOutputClassifier.predict_proba` when the
  underlying estimators lack `predict_proba` is unchanged.

Compatibility result: pass.
