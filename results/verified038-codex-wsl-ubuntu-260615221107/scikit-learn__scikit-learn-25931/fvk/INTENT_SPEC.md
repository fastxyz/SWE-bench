# Intent Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 source change for
`repo/sklearn/ensemble/_iforest.py`, specifically:

- `IsolationForest.fit`
- `IsolationForest.score_samples`
- the new private `IsolationForest._score_samples`
- the interaction with `BaseEstimator._validate_data` feature-name checking

The proof is about the warning/validation behavior and the offset scoring call
introduced by `contamination != "auto"`. It abstracts the numerical details of
tree scoring and percentile computation as uninterpreted but stable functions.

## Intent-only obligations

I-001. Fitting an `IsolationForest` with a pandas DataFrame whose columns are
valid feature names and `contamination` is a non-`"auto"` value must not emit
the warning:

`X does not have valid feature names, but IsolationForest was fitted with feature names`

I-002. `fit` may still validate its original user input and record
`feature_names_in_` when the input has valid string feature names.

I-003. The internal `fit` computation of `offset_` for
`contamination != "auto"` must use the already validated training data and must
not perform a second user-input feature-name validation on that transformed
internal array.

I-004. The public `score_samples` method must keep its existing public
validation behavior: it checks fitted state, validates user input with
`reset=False`, and only then computes scores.

I-005. Public `score_samples` must continue to warn when an estimator fitted
with feature names is later scored on user-supplied data with no valid feature
names.

I-006. Public scoring values must be preserved: `score_samples(X)` continues to
return the opposite of the chunked raw IsolationForest scores, and
`decision_function(X)` remains `score_samples(X) - offset_`.

I-007. `contamination == "auto"` remains unchanged: `fit` sets `offset_` to
`-0.5` and does not need the training-data scoring path to define the offset.

I-008. Sparse input support must remain compatible with the existing scoring
surface: `fit` may validate sparse input as CSC for tree building, but scoring
must use CSR before tree `apply` calls.

I-009. The public method signatures and public return shapes of `fit`,
`score_samples`, `decision_function`, and `predict` must not change.

## Default-domain assumptions

D-001. The proof ranges over inputs accepted by `IsolationForest.fit` and
`score_samples` after their documented validation steps. Invalid constructor
parameters, invalid array shapes, and invalid feature-name types are delegated
to existing validation logic outside this patch.

D-002. A pandas DataFrame with all-string column names has valid feature names;
an ndarray or sparse matrix has no feature names. This follows from
`sklearn.utils.validation._get_feature_names`.

D-003. This is a partial-correctness audit of the relevant validation/scoring
control flow. It does not prove termination, parallel execution behavior, or
the mathematical correctness of IsolationForest scoring itself.
