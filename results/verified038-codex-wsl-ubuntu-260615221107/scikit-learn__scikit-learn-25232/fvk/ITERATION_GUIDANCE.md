# Iteration Guidance

Status: constructed for FVK audit; not machine-checked.

## Decision

V1 stands unchanged. The FVK findings and proof obligations do not justify an
additional production-code edit.

## Traceability

- F-001 and O-001 justify keeping the V1 constructor/API addition.
- F-002 and O-002 justify keeping the V1 forwarding to `SimpleImputer`.
- F-003 and O-003 justify keeping the V1 constant-strategy `valid_mask`
  special case.
- F-004 and O-004 justify keeping non-constant behavior unchanged.
- O-005 justifies keeping `fill_value=None` as the default and delegating
  default constant selection to `SimpleImputer`.

## Suggested Tests For A Future Non-Benchmark Environment

Do not edit tests in this benchmark. In a normal development environment, add
or keep tests that cover:

- `IterativeImputer(initial_strategy="constant", fill_value=some_number)`
  forwards the number to `initial_imputer_`.
- `IterativeImputer(initial_strategy="constant", fill_value=np.nan,
  estimator=HistGradientBoostingRegressor(...))` does not drop all features
  during initial imputation.
- `fill_value=None` preserves previous constant-strategy defaults.
- `fill_value` is ignored for non-constant `initial_strategy` values except for
  normal estimator parameter storage.

## Future Proof Escalations

This FVK pass models the bug-fix slice only. A broader proof would need a fuller
Python/NumPy/scikit-learn semantics for arrays, masks, estimator fitting,
feature dropping, sparse matrices, all-empty target columns, and convergence.

