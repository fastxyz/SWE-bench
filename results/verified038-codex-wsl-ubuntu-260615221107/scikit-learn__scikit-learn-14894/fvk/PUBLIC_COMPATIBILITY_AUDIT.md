# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public symbols

None. V1 changes a local expression inside `BaseLibSVM._sparse_fit` and does not
change any estimator class, method signature, public attribute name, or import.

## Fitted attribute compatibility

- `dual_coef_`: remains a SciPy CSR matrix in the sparse path and keeps the
  explicit shape `(n_class, n_SV)`.
- `support_`, `support_vectors_`, `_n_support`, `intercept_`, `probA_`,
  `probB_`, and `fit_status_`: unchanged by the patch.
- `shape_fit_`, `_dual_coef_`, and `_intercept_`: assigned by existing code after
  `_sparse_fit` returns; the patch only lets the empty-support case reach that
  existing code.

## Public callers and overrides

`_sparse_fit` is an internal method selected by `BaseLibSVM.fit`. V1 does not add
arguments, remove arguments, or change dispatch. No subclass override or public
callsite update is required.

## Compatibility verdict

Compatible. No public API or fitted-attribute contract change is required.
