# Intent Spec

Status: constructed, not machine-checked.

1. A fitted `MultiOutputClassifier` must expose `classes_`.
   Evidence: the public hint says, "All classifiers should store `classes_`
   when fitted."

2. `MultiOutputClassifier.classes_` must be a per-output collection aligned
   with the internal fitted estimators.
   Evidence: the issue says that for `MultiOutputClassifier`, the needed value
   is `mo_clf.estimators_[i].classes_`; the public hint says to add
   `classes_` like `ClassifierChain`.

3. `cross_val_predict(mo_clf, X, Y, cv=5, method='predict_proba')` must not fail
   with `AttributeError: 'MultiOutputClassifier' object has no attribute
   'classes_'` after fitting the estimator.
   Evidence: the issue's expected result is an array with prediction
   probabilities, and the actual result is that AttributeError.

4. Existing behavior outside the missing fitted attribute should be preserved:
   fitting, prediction, probability output shape/order, delegated
   `partial_fit` availability, and the existing `ValueError` when underlying
   estimators lack `predict_proba`.
   Evidence: `MultiOutputClassifier` docstrings and existing source behavior.

5. The audited domain assumes wrapped classifiers follow the scikit-learn
   classifier contract and expose their own `classes_` after successful fitting.
   Evidence: public hint says all classifiers should store `classes_` when
   fitted.
