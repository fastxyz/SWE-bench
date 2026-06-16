# Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Code Decision

V1 stands unchanged.

Rationale:

- F-1 and PO-1 through PO-3 show that V1 removes the reported
  `AttributeError` by adding the per-output fitted `classes_` list that
  `_fit_and_predict` indexes.
- F-2 and PO-4 show that keeping the `partial_fit` addition is justified by the
  public fitted-classifier contract.
- F-3 and PO-7 show that modifying `_validation.py` is unnecessary and would be
  a less targeted special case.
- F-5 and PO-5 show that V1 preserves public signatures and delegated
  availability.

## Recommended Tests For A Normal Development Environment

Do not add tests in this benchmark task. In a normal development branch, useful
public tests would be:

1. `cross_val_predict(MultiOutputClassifier(LinearDiscriminantAnalysis()), X, Y,
   cv=5, method='predict_proba')` returns list-valued probabilities without
   `AttributeError`.
2. After `MultiOutputClassifier(LogisticRegression(...)).fit(X, Y)`,
   `classes_` is a list whose entries equal each fitted estimator's `classes_`.
3. After successful incremental fitting with an estimator that supports
   `partial_fit`, `classes_` is also present and aligned with `estimators_`.
4. `MultiOutputRegressor` still has no classifier-only `classes_`.

## Residual Risk

- The proof is constructed but not machine-checked. Run the emitted K commands
  before treating it as a machine-verified proof.
- The mini semantics abstracts away real NumPy arrays, joblib scheduling,
  estimator internals, and probability values. It keeps the ordered metadata
  property visible, which is the property needed for this issue.
- The proof assumes wrapped classifiers obey the scikit-learn fitted classifier
  contract and expose `classes_`.

## Next Iteration If A Failure Is Found Elsewhere

If later public evidence shows a wrapped classifier can validly be fitted
without `classes_`, refine PO-6 and decide whether `MultiOutputClassifier`
should derive labels from `y` instead. Current public evidence does not support
that broader behavior.
