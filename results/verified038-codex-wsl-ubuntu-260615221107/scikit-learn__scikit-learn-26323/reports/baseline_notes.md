# Baseline Notes

## Root Cause

`ColumnTransformer.set_output` configured output on estimators listed in
`transformers` and, when already fitted, `transformers_`. It did not configure
an estimator supplied through the `remainder` parameter before fitting.

During `fit_transform`, `ColumnTransformer` clones the unfitted remainder
estimator from `self.remainder` when there are remaining columns. Because the
constructor-level remainder estimator never received the pandas output
configuration, the fitted clone produced the default ndarray output. In the
reported case, this made `_hstack` concatenate a mix of pandas and ndarray
outputs and lose the original pandas boolean dtype for the remainder-related
result.

## Changed Files

`repo/sklearn/compose/_column_transformer.py`

- Updated the `set_output` docstring to state that `remainder` is configured.
- Added a `_safe_set_output` call for `self.remainder` when it is an estimator
  rather than the `"passthrough"` or `"drop"` sentinel. This ensures
  pre-fit `set_output(transform="pandas")` is preserved when the remainder
  estimator is later cloned and fitted, while the existing `transformers_`
  handling continues to cover fitted estimators for post-fit calls.

## Assumptions and Alternatives Considered

- I assumed `remainder` should follow the same output-configuration contract as
  explicitly listed transformers because it is a nested transformer whenever it
  is an estimator.
- I considered configuring the remainder only inside fit-time remainder
  validation, after the remaining columns are known. I rejected that because the
  existing `set_output` method is the central place where meta-estimator child
  output configuration is propagated, and explicit transformers are configured
  there regardless of their eventual selected columns.
- I kept the change limited to non-test source code as required and did not run
  tests or import code in this environment.
