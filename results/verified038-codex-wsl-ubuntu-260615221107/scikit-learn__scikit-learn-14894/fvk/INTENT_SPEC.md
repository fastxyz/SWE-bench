# Intent Specification

Status: constructed from public evidence, not machine-checked.

## Intended behavior

1. Sparse libsvm estimators must complete `_sparse_fit` for a valid libsvm
   result even when `support_vectors_` is empty.

2. In that empty-support-vector case, `dual_coef_` must be representable as an
   empty CSR matrix. For the reported SVR case this means one row and zero
   columns, equivalent to `sp.csr_matrix([])`.

3. For non-empty support vectors, the sparse path must preserve the existing
   public shape contract for `dual_coef_`: one row for SVR, NuSVR, and
   OneClassSVM, and `n_classes - 1` rows for SVC/NuSVC classifiers.

4. The fix must not change public estimator signatures, dense fitting behavior,
   libsvm training inputs, or the shape of other fitted attributes.

## Domain

This FVK audit covers the Python-side CSR reconstruction in
`BaseLibSVM._sparse_fit` after `libsvm_sparse.libsvm_sparse_train` has returned.
The domain is:

- `n_class >= 1`;
- `n_SV >= 0`;
- `dual_coef_data.size == n_class * n_SV`;
- `support_vectors_.shape[0] == n_SV`;
- the caller is already in the sparse fit path for a valid estimator fit.

The audit does not prove libsvm solver correctness, Cython memory-copy
correctness, prediction correctness, or termination of the optimizer.
