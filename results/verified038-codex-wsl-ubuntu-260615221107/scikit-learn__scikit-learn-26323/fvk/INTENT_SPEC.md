# Intent Specification

Status: constructed for FVK audit, not machine-checked.

## Public Intent

1. `ColumnTransformer.set_output(transform="pandas")` must configure every
   child transformer that can contribute to `transform` or `fit_transform`
   output.
2. If `remainder` is an estimator, it is a child transformer for all columns
   not selected by explicit transformers, so it must receive the same output
   configuration as explicit transformers.
3. A pre-fit call to `set_output(transform="pandas")` must affect later
   `fit_transform`, including the fitted clone of a remainder estimator.
4. With pandas output requested, dense stacking should use the pandas branch
   when every child output is a pandas object. That branch preserves pandas
   dtypes and column labels for the concatenated result.
5. The sentinel remainders `"drop"` and `"passthrough"` are not estimator
   instances and must not be passed to `_safe_set_output` as child estimators.
6. `transform=None` means configuration is unchanged. It is a no-op for
   output configuration propagation.
7. If `transform` is non-`None` and a participating estimator can transform
   but has no `set_output`, `_safe_set_output` should keep raising the existing
   "Unable to configure output" error.

## Out of Scope

1. Full pandas dtype semantics are not reimplemented in the formal model. The
   model tracks the discriminating property for this issue: whether each child
   output is pandas-configured or default-configured.
2. Termination and performance of `ColumnTransformer.fit_transform` are not
   proved; the proof is partial correctness only.
