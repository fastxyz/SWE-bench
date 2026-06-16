# Intent Spec

This is the intent-only specification for the voting-estimator fix, before
accepting the candidate implementation as the contract.

1. A voting estimator may contain estimators set to `None` through
   `set_params(name=None)`. Those entries are dropped from fitting and from the
   fitted estimator collection.
2. Passing `sample_weight` to `VotingClassifier.fit` or `VotingRegressor.fit`
   must not cause the `sample_weight` support check to inspect dropped
   estimators.
3. Passing `sample_weight` must still require every non-dropped estimator to
   support a `sample_weight` fit parameter.
4. Fitting with at least one non-dropped estimator should fit exactly the
   non-dropped estimators, in estimator-list order, passing `sample_weight`
   when supplied.
5. The fitted-name view `named_estimators_` should name the same fitted
   non-dropped estimators, in the same order, because public documentation says
   it provides access to fitted estimators.
6. If all estimators are dropped, the existing public error behavior remains:
   "All estimators are None. At least one is required!".
7. Existing validations outside the dropped-estimator/sample-weight interaction
   remain framed: invalid estimator list, weights-length mismatch, and estimator
   name validation are not relaxed by this fix.

Default-domain assumptions:

- Joblib `Parallel` preserves the order of results for the iterable of delayed
  fit calls.
- `has_fit_parameter(est, "sample_weight")` correctly detects whether an active
  estimator accepts the keyword.
- The proof is partial correctness over the routing behavior; it does not prove
  properties of the machine-learning algorithms inside the base estimators.
